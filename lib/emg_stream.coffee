EventEmitter = require('events').EventEmitter
#util = require('util')

class EMG extends EventEmitter
  constructor: (opt)->
    super

  newData: (raw)=>
    @emit 'data', raw
  

module.exports = EMG
