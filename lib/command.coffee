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
