EventEmitter = require('events').EventEmitter

class Pose extends EventEmitter
  Arm: {
    UNKNOWN: 0
    RIGHT: 1
    LEFT: 2
  }

  XDir: {
    UNKNOWN: 0
    X_TOWARD_WRIST: 1
    X_TOWARD_ELBOW: 2
  }

  Pose: {
    REST: 0
    FIST: 1
    WAVE_IN: 2
    WAVE_OUT: 3
    FINGER_SPREAD: 4
    THUMB_TO_PINKY: 5
    UNKNOWN: 255
  }

  constructor: (opt)->
    super

  newData: (raw)=>
    type = raw.readUInt8(0)
    val = raw.readUInt8(1)
    xdir = raw.readUInt8(2)
    if type == 1
      @emit 'arm', [val, xdir]
    else if type == 2
      @emit 'arm', [0, 0]
    else if type == 3
      @emit 'pose', val
    else
      @emit 'error', new Error('unknown classifier: ' + type)
    
module.exports = Pose
