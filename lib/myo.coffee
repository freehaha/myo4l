noble = require('noble')
constants = require('./constants')
command = require('./command')
async = require('async')
IMU = require('./imu_stream')

class Myo
  constructor: (@devName)->
    @dev = null
    @connected = false
    @services = {}
    @chars = {}
    @fVersion = null
    @imuStream = new IMU()
    
  onConnect: =>
    @readNecessaryInfo()

  onRssiUpdate: (rssi)=>
    console.log rssi

  onDisconnect: =>
    @connected = false

  disconnect: ->
    if @connected
      @dev.disconnect()

  getChar: (suid, cuid, cb)->
    if suid of @chars
      if cuid of @chars[suid]
        return @chars[suid][cuid]
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
    @getService constants.CONTROL_SERVICE_UUID, (err, s)=>
      if err
        console.error err
        return

      console.log 'getting firmware version...'
      s.discoverCharacteristics [constants.FIRMWARE_VERSION_CHAR_UUID], (err, chars) =>
        unless not err and chars and chars.length > 0
          console.error 'failed to get firmware version'
          if err
            console.error err
          return
        chars[0].read (err, version) =>
          maj = version.readUInt16LE(0)
          min = version.readUInt16LE(2)
          pat = version.readUInt16LE(4)
          hrd = version.readUInt16LE(6)
          @fVersion = "#{maj}.#{min}.#{pat}"
          console.log "version: #{@fVersion} hardware: #{hrd}"
          @connected = true
          #@listServices()
          # don't do parallel here becaue noble can't handle the interleved requests
          async.series [
            (cb) => @setNotification(constants.EMG_SERVICE_UUID, constants.EMG0_DATA_CHAR_UUID, true, false, null, cb)
            (cb) => @setNotification(constants.IMU_SERVICE_UUID, constants.IMU_DATA_CHAR_UUID, true, false, @imuStream, cb)
            (cb) => @setNotification(constants.FV_SERVICE_UUID, constants.FV_DATA_CHAR_UUID, true, false, null, cb)
            (cb) => @setNotification(constants.CLASSIFIER_SERVICE_UUID, constants.CLASSIFIER_EVENT_CHAR_UUID, true, true, null, cb)
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

  listServices: ->
    @dev.discoverAllServicesAndCharacteristics (err, services, chars)->
      for c in chars
        console.log c._serviceUuid, c.uuid

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
