EventEmitter = require('events').EventEmitter

LOCKING_NONE = 0
LOCKING_STANDARD = 1

class Pose extends EventEmitter
  constructor: (opt)->
    super
    @lockingPolicy = opt?.policy || 0

  setLockingPolicy: (@lockingPolicy)->
    #

  newData: (raw)=>
    type = raw.readUInt8(0)
    val = raw.readUInt8(1)
    xdir = raw.readUInt8(2)
    if type == 1
      @emit 'arm', [val, xdir]
    else if type == 2
      @emit 'arm', [0, 0]
    else if type == 3
      #TODO: deal with policy
      @emit 'pose', val
    else if type == 4
      @emit 'unlocked'
    else if type == 5
      @emit 'locked'
    else
      @emit 'error', new Error('unknown classifier: ' + type)

module.exports = Pose
