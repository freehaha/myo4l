Command = {
  getSetModeCommand: (emgMode, imuMode, classifierMode)->
    SETMODE_SIZE = 5
    command = new Buffer(SETMODE_SIZE)
    command.writeUInt8(1, 0) # set mode
    command.writeUInt8(SETMODE_SIZE-2, 1) # payload size
    command.writeUInt8(emgMode, 2) # EMG mode
    command.writeUInt8(imuMode, 3) # IMU mode
    command.writeUInt8(classifierMode, 4) # classification
    return command

  getVibrateCommand: (duration)->
    VIBRATE_SIZE = 3
    command = new Buffer(VIBRATE_SIZE)
    command.writeUInt8(3, 0) # set mode
    command.writeUInt8(VIBRATE_SIZE-2, 1)
    command.writeUInt8(duration, 2) # classification
    return command

  getUnlockCommand: (type)->
    UNLOCK_SIZE = 3
    command = new Buffer(UNLOCK_SIZE)
    command.writeUInt8(10, 0) # set mode
    command.writeUInt8(UNLOCK_SIZE-2, 1)
    command.writeUInt8(type, 2) # classification
    return command

  getLockCommand: ()->
    # FIXME should be similar to unlock? but don't know the parameters...
    LOCK_SIZE = 2
    command = new Buffer(LOCK_SIZE)
    command.writeUInt8(11, 0) # set mode
    command.writeUInt8(0, 1)
    return command

  lockPolicy: {
    NONE: 0
    STANDARD: 1
  }
  unlock: {
    TIMED: 1
    HOLD: 2
  }
  classifier: {
    DISABLE: 0
    ENABLE: 1
  }
  imu: {
    DISABLE: 0
    ENABLE: 1
  }
  emg: {
    DISABLE: 0
    FV: 1
    STREAM: 2
  }
}
  
module.exports = Command
