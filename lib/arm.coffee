class Arm
  _armString: {
    0: 'unknown'
    1: 'right'
    2: 'left'
  }
  _xdirString: {
    0: 'unknown'
    1: 'toward_wrist'
    2: 'toward_elbow'
  }
  constructor: (arm) ->
    @arm = arm[0]
    @xdir = arm[1]

  xdirString: ->
    @_xdirString[@xdir]

  armString: ->
    @_armString[@arm]

Arm.Arm = {
  UNKNOWN: 0
  RIGHT: 1
  LEFT: 2
}

Arm.XDir = {
  UNKNOWN: 0
  X_TOWARD_WRIST: 1
  X_TOWARD_ELBOW: 2
}

module.exports = Arm
  
