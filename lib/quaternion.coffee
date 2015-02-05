QUAT_SCALE = 16384.0
  
class Quaternion
  constructor: (buf)->
    @x = buf.readInt16LE(0) / QUAT_SCALE
    @y = buf.readInt16LE(2) / QUAT_SCALE
    @z = buf.readInt16LE(4) / QUAT_SCALE
    @w = buf.readInt16LE(6) / QUAT_SCALE

  getPitch: ->
    Math.atan2(2*@x*@w - 2*@y*@z, 1 - 2*@x*@x - 2*@z*@z)
  getYaw: ->
    Math.asin(2*@x*@y + 2*@z*@w)
  getRoll: ->
    Math.atan2(2*@y*@w - 2*@x*@z, 1 - 2*@y*@y - 2*@z*@z)

module.exports = Quaternion
