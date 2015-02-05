EventEmitter = require('events').EventEmitter
#util = require('util')

class IMU extends EventEmitter
  constructor: (opt)->
    super

  newData: (raw)=>
    quat = raw.slice(0, 8)
    acc = raw.slice(8, 14)
    gyro = raw.slice(14, 20)
    @emit 'data', [quat, acc, gyro]
    
  

module.exports = IMU
