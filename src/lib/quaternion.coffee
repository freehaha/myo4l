util = require('util')
QUAT_SCALE = 16384.0

class Quaternion
  constructor: (buf)->
    if Buffer.isBuffer(buf)
      @w = buf.readInt16LE(0) / QUAT_SCALE
      @x = buf.readInt16LE(2) / QUAT_SCALE
      @y = buf.readInt16LE(4) / QUAT_SCALE
      @z = buf.readInt16LE(6) / QUAT_SCALE
    else if util.isArray(buf)
      [@w, @x, @y, @z] = buf

  length: ->
    return Math.sqrt(@x * @x + @y * @y + @z * @z + @w * @w)

  normalize: ->
    len = @length()
    @x /= len
    @y /= len
    @z /= len
    @w /= len

  getYaw: ->
    Math.atan2(2*@z*@w + 2*@x*@y, 1 - 2*@y*@y - 2*@z*@z)
  getPitch: ->
    Math.asin(2*@w*@y + 2*@z*@x)
  getRoll: ->
    Math.atan2(2*@x*@w + 2*@y*@z, 1 - 2*@y*@y - 2*@x*@x)

module.exports = Quaternion
