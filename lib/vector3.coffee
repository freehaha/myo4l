class Vector3 extends Array
  constructor: (buf, scale)->
    @[0] = buf.readInt16LE(0) / scale
    @[1] = buf.readInt16LE(2) / scale
    @[2] = buf.readInt16LE(4) / scale

Vector3.ACCEL = 2048.0
Vector3.GYRO = 16.0
module.exports = Vector3
