// Generated by CoffeeScript 1.8.0
(function() {
  var QUAT_SCALE, Quaternion, util;

  util = require('util');

  QUAT_SCALE = 16384.0;

  Quaternion = (function() {
    function Quaternion(buf) {
      if (Buffer.isBuffer(buf)) {
        this.w = buf.readInt16LE(0) / QUAT_SCALE;
        this.x = buf.readInt16LE(2) / QUAT_SCALE;
        this.y = buf.readInt16LE(4) / QUAT_SCALE;
        this.z = buf.readInt16LE(6) / QUAT_SCALE;
      } else if (util.isArray(buf)) {
        this.w = buf[0], this.x = buf[1], this.y = buf[2], this.z = buf[3];
      }
    }

    Quaternion.prototype.length = function() {
      return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
    };

    Quaternion.prototype.normalize = function() {
      var len;
      len = this.length();
      this.x /= len;
      this.y /= len;
      this.z /= len;
      return this.w /= len;
    };

    Quaternion.prototype.getYaw = function() {
      return Math.atan2(2 * this.z * this.w + 2 * this.x * this.y, 1 - 2 * this.y * this.y - 2 * this.z * this.z);
    };

    Quaternion.prototype.getPitch = function() {
      return Math.asin(2 * this.w * this.y + 2 * this.z * this.x);
    };

    Quaternion.prototype.getRoll = function() {
      return Math.atan2(2 * this.x * this.w + 2 * this.y * this.z, 1 - 2 * this.y * this.y - 2 * this.x * this.x);
    };

    return Quaternion;

  })();

  module.exports = Quaternion;

}).call(this);