Vector3 = {
  parse: (buf, scale)->
    return [
      buf.readInt16LE(0) / scale
      buf.readInt16LE(2) / scale
      buf.readInt16LE(4) / scale
    ]
}
Vector3.ACCEL = 2048.0
Vector3.GYRO = 16.0
module.exports = Vector3
