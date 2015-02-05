Myo = require('./lib/myo')
Quat = require('./lib/quaternion')

m = new Myo('FreeMyo')
m.connect()
m.imuStream.on 'data', (data)->
  console.log new Quat(data[0]).getYaw()
process.on 'SIGINT', ->
  if m.connected
    m.disconnect()
  else
    process.exit(0)

