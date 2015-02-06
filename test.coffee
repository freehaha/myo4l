Myo = require('./lib/myo')
Quat = require('./lib/quaternion')

m = new Myo('FreeMyo')
m.connect()

m.imuStream.on 'data', (data)->
  console.log new Quat(data[0]).getYaw()

m.poseStream.on 'pose', (pose)->
  console.log 'pose', pose

m.poseStream.on 'arm', (arm, dir)->
  console.log arm, dir

process.on 'SIGINT', ->
  if m.connected
    m.disconnect()
  else
    process.exit(0)

