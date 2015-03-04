noble = require('noble')
constants = require('./constants')
command = require('./command')
async = require('async')
Imu = require('./imu_stream')
Emg = require('./emg_stream')
Pose = require('./pose_stream')
EventEmitter = require('events').EventEmitter

LOCKING_NONE = 0
LOCKING_STANDARD = 1

CONN_DISCONNECTED = 0
CONN_CONNECTING = 1
CONN_CONNECTED = 2

class Myo extends EventEmitter
  constructor: (@devName)->
    super
    @_inited = false
    @dev = null
    @connection = CONN_DISCONNECTED
    @services = {}
    @chars = {}
    @fVersion = null
    @imuStream = new Imu()
    @emgStream = new Emg()
    @poseStream = new Pose()
    @imuMode = command.imu.ENABLE
    @cfyMode = command.classifier.ENABLE
    @emgMode = command.emg.DISABLE
    noble.on 'discover', @onDiscover

  onConnect: =>
    # do a discovery first to cache possible service and chars
    @_discovery =>
      @readNecessaryInfo()

  onRssiUpdate: (rssi)=>
    @emit 'rssi', rssi

  onDisconnect: =>
    @connection = CONN_DISCONNECTED
    @emit 'disconnected'

  disconnect: ->
    if @connection isnt CONN_DISCONNECTED
      @dev.disconnect()

  _discovery: (cb)->
    @dev.discoverAllServicesAndCharacteristics (err, ss, cs) =>
      for s in ss
        @services[s.uuid] = s
      for c in cs
        if c._serviceUuid not of @chars
          @chars[c._serviceUuid] = {}
        @chars[c._serviceUuid][c.uuid] = c

      process.nextTick ->
        cb(err)
  getChar: (suid, cuid, cb)->
    if suid of @chars
      if cuid of @chars[suid]
        cb null, @chars[suid][cuid]
        return
    else
      @chars[suid] = {}

    @dev.discoverSomeServicesAndCharacteristics [suid], [cuid], (err, ss, cs)=>
      if err
        cb(err, null)
        return
      unless ss and cs and ss.length and cs.length
        cb new Error("charactistic not found"), null
        return

      @chars[suid][cuid] = cs[0]
      cb null, cs[0]

  getService: (uuid, cb)->
    if uuid of @services
      cb(null, @services[uuid])
      return

    @dev.discoverServices [uuid], (err, services)=>
      unless not err and services and services.length > 0
        if not err
          err = new Error("unknown")
        cb(err, null)
        return

      @services[uuid] = services[0]
      cb(null, services[0])

  setNotification: (suid, cuid, enable, indicate, stream, cb)->
    # maybe do this using handles, should be faster
    val = 0x0000
    if enable
      if indicate
        val = 0x0002
      else
        val = 0x0001
    else
      val = 0x0000
    valBuf = new Buffer(2)
    valBuf.writeUInt16LE(val, 0)
    @getChar suid, cuid, (err, c)=>
      if err
        cb err
        return
      #c.notify true
      if stream
        c.on 'read', (data, notify)->
          return unless notify
          stream.newData(data)

      c.discoverDescriptors (err, descs)->
        if err
          cb err
          return
        if descs.length <= 0
          cb new Error('failed to set descriptor')
          return
        else if descs.length > 1
          cb new Error('unexpected amount of descriptors: ' + cuid)
        descs[0].writeValue valBuf, (err)->
          cb err

  writeControlCommand: (command, cb)->
    @getChar constants.CONTROL_SERVICE_UUID, constants.COMMAND_CHAR_UUID, (err, char)=>
      char.write command, false, (err)->
        return unless cb
        cb err

  _vibDuration: {
    'short': 1
    'medium': 2
    'long': 3
  }

  vibrate: (duration)->
    if duration not of @_vibDuration
      return
    @writeControlCommand command.getVibrateCommand(@_vibDuration[duration])

  requestRssi: ->
    @dev.updateRssi()

  _unlockType: {
    'timed': command.unlock.TIMED
    'hold': command.unlock.HOLD
  }
  unlock: (type)->
    if type not of @_unlockType
      return
    #@poseStream.unlock(@_unlockType[type])
    @writeControlCommand command.getUnlockCommand(@_unlockType[type])

  lock: ->
    @poseStream.lock()
    @emit 'locked'

  _lockingPolicy: {
    'none': LOCKING_NONE
    'standard': LOCKING_STANDARD
  }

  setLockingPolicy: (type)->
    if type not of @_lockingPolicy
      return
    lockingPolicy = @_lockingPolicy[type]
    @poseStream.setLockingPolicy lockingPolicy
    @emit 'locking_policy_ack', 'success'

  getLockingPolicy: ->
    @poseStream.lockingPolicy

  setMode: (emg, imu, classifier, cb)->
    @emgMode = emg
    @imuMode = imu
    @cfyMode = classifier
    @writeControlCommand command.getSetModeCommand(
      @emgMode,
      @imuMode,
      @cfyMode,
    ), cb

  setStreamEmg: (enable)->
    if enable is 'enabled'
      enable = command.emg.STREAM
    else
      enable = command.emg.DISABLE

    @setMode enable, @imuMode, @cfyMode, (err)=>
      if err
        @emit 'set_stream_emg_ack', 'fail'
      else
        @emit 'set_stream_emg_ack', 'success'

  readFirmwareVersion: ->
    @getChar constants.CONTROL_SERVICE_UUID, constants.FIRMWARE_VERSION_CHAR_UUID, (err, c) =>
      c.read (err, version) =>
        maj = version.readUInt16LE(0)
        min = version.readUInt16LE(2)
        pat = version.readUInt16LE(4)
        hrd = version.readUInt16LE(6)
        fVersion = "#{maj}.#{min}.#{pat}"
        @version = [maj, min, pat, hrd]
        console.log "version: #{fVersion} hardware: #{hrd}"
        async.parallel [
          (cb) => @setNotification(constants.EMG_SERVICE_UUID, constants.EMG0_DATA_CHAR_UUID, true, false, @emgStream, cb)
          (cb) => @setNotification(constants.IMU_SERVICE_UUID, constants.IMU_DATA_CHAR_UUID, true, false, @imuStream, cb)
          (cb) => @setNotification(constants.FV_SERVICE_UUID, constants.FV_DATA_CHAR_UUID, true, false, null, cb)
          (cb) => @setNotification(constants.CLASSIFIER_SERVICE_UUID, constants.CLASSIFIER_EVENT_CHAR_UUID, true, true, @poseStream, cb)
        ], (err)=>
          if err
            console.error 'failed to set notifications'
            console.error err
            return
          # set mode
          @setMode command.emg.DISABLE, command.imu.ENABLE, command.classifier.ENABLE, (err)=>
            if err
              console.error "failed to write init control command", err
              return
            console.log "initialized"
            @vibrate('short')
            @emit 'connected'
            @connection = CONN_CONNECTED

  readNecessaryInfo: ->
    @readFirmwareVersion()
    #@setNotifications()

  initMyo: ->
    console.log 'found myo, connecting...'
    unless @_inited
      @dev.on 'connect', @onConnect
      @dev.on 'disconnect', @onDisconnect
      @dev.on 'rssiUpdate', @onRssiUpdate
      @_inited = true
    @dev.connect (err)->
      if err
        console.error err


  onDiscover: (peri)=>
    if @connection isnt CONN_CONNECTING
      noble.stopScanning()
      return

    return unless @connection is CONN_CONNECTING
    len = peri.advertisement.localName.length
    if peri.advertisement.localName.substring(0, len - 1) == @devName
      @dev = peri
      @initMyo()
      noble.stopScanning()
    return

  connect: ->
    return unless @connection is CONN_DISCONNECTED
    @connection = CONN_CONNECTING
    noble.startScanning()

Myo.CONN_DISCONNECTED = CONN_DISCONNECTED
Myo.CONN_CONNECTING = CONN_CONNECTING
Myo.CONN_CONNECTED = CONN_CONNECTED
module.exports = Myo
