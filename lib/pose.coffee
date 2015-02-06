class Pose
  _pStringMapping: {
    0: 'rest'
    1: 'fist'
    2: 'wave_in'
    3: 'wave_out'
    4: 'finger_spread'
    5: 'thumb_to_pinky'
  }
  constructor: (@pose)->

  toString: ->
    return @_pStringMapping[@pose]

Pose.Pose = {
  REST: 0
  FIST: 1
  WAVE_IN: 2
  WAVE_OUT: 3
  FINGER_SPREAD: 4
  THUMB_TO_PINKY: 5
  UNKNOWN: 255
}

module.exports = Pose
