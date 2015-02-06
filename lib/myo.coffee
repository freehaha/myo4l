noble = require('noble')
constants = require('./constants')
command = require('./command')
async = require('async')
Imu = require('./imu_stream')
Emg = require('./emg_stream')
Pose = require('./pose_stream')

class Myo
  constructor: (@devName)->
    @dev = null
    @connected = false
    @services = {}
    @chars = {}
    @fVersion = null
    @imuStream = new Imu()
    @emgStream = new Emg()
    @poseStream = new Pose()
    
  onConnect: =>
    # do a discovery first to cache possible service and chars
    @_discovery =>
      @readNecessaryInfo()

  onRssiUpdate: (rssi)=>
    console.log rssi

  onDisconnect: =>
    @connected = false

  disconnect: ->
    if @connected
      @dev.disconnect()

  _discovery: (cb)->
    @dev.discoverAllServicesAndCharacteristics (err, ss, cs) =>
      for s in ss
        @services[s.uuid] = s
      for c in cs
        if c._serviceUuid not of @chars
          @chars[c._serviceUuid] = {}
        @chars[c._serviceUuid][c.uuid] = c

      console.log "done discovery, found #{ss.length} services, #{cs.length} characteristics"
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
      c.notify true
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
        cb err

  setMode: (emg, imu, classifier)->
    #
  readFrimwareVersion: ->
    @getChar constants.CONTROL_SERVICE_UUID, constants.FIRMWARE_VERSION_CHAR_UUID, (err, c) =>
      c.read (err, version) =>
        maj = version.readUInt16LE(0)
        min = version.readUInt16LE(2)
        pat = version.readUInt16LE(4)
        hrd = version.readUInt16LE(6)
        @fVersion = "#{maj}.#{min}.#{pat}"
        console.log "version: #{@fVersion} hardware: #{hrd}"
        @connected = true
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
          @writeControlCommand command.getSetModeCommand(
            command.emg.DISABLE,
            command.imu.ENABLE,
            command.classifier.ENABLE,
          ), (err)=>
            if err
              console.error "failed to write init control command", err
              return
            console.log "initialized"
            @activateListeners()

  activateListeners: ->
    #@getChar(constants.)
    
  readNecessaryInfo: ->
    @readFrimwareVersion()
    #@setNotifications()

  initMyo: ->
    console.log 'found myo, connecting...'
    @dev.on 'connect', @onConnect
    @dev.on 'disconnect', @onDisconnect
    @dev.on 'rssiUpdate', @onRssiUpdate
    @dev.connect()
  

  connect: ->
    noble.on 'discover', (peri) =>
      len = peri.advertisement.localName.length
      if peri.advertisement.localName.substring(0, len - 1) == @devName
        @dev = peri
        @initMyo()
        noble.stopScanning()
      return
    noble.startScanning()

module.exports = Myo
