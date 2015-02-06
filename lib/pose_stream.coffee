EventEmitter = require('events').EventEmitter

class Pose extends EventEmitter
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
