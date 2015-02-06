Myo = require('./lib/myo')
Quat = require('./lib/quaternion')
Vector3 = require('./lib/vector3')
WS = require('ws').Server
Pose = require('./lib/pose')
Arm = require('./lib/arm')
express = require('express')
http = require('http')

m = new Myo('FreeMyo')
m.connect()

app = express()
server = http.createServer app
wss = new WS({
  server: server
  path: '/myo/3'
  verifyClient: verifyClient
})

verifyClient = (info, cb)->
  console.log info
  cb(true)

getTimestamp = ->
  new Date().getTime().toString()

m.on 'connected', ->
  wss.on 'connection', (ws)->
    ws.on 'message', (message)->
      console.log "receive", message

    sendImu = (data)->
      ws.send JSON.stringify [
        'event'
        {
          type: 'orientation'
          timestamp: getTimestamp()
          myo: 0
          orientation: new Quat(data[0])
          accelerometer: new Vector3(data[1], Vector3.ACCEL)
          gyroscope: new Vector3(data[2], Vector3.GYRO)
        }
      ]
    sendPose = (pose)->
      ws.send JSON.stringify [
        'event'
        {
          type: 'pose'
          timestamp: getTimestamp()
          myo: 0
          pose: new Pose(pose).toString()
        }
      ]
      #
    sendArm = (arm)->
      if arm[0] != Arm.Arm.UNKNOWN
        arm = new Arm(arm)
        ws.send JSON.stringify [
          'event'
          {
            type: 'arm_synced'
            timestamp: getTimestamp()
            myo: 0
            arm: arm.armString()
            x_direction: arm.xdirString()
          }
        ]
      else
        ws.send JSON.stringify [
          'event'
          {
            type: 'arm_unsynced'
            timestamp: getTimestamp()
            myo: 0
          }
        ]
    m.poseStream.addListener 'pose', sendPose
    m.poseStream.addListener 'arm', sendArm
    m.imuStream.addListener 'data', sendImu
    ws.on 'close', ->
      m.imuStream.removeListener 'data', sendImu
      m.poseStream.removeListener 'pose', sendPose

m.poseStream.on 'pose', (pose)->
  console.log 'pose', pose

m.poseStream.on 'arm', (arm)->
  console.log arm[0], arm[1]

process.on 'SIGINT', ->
  wss.close()
  if m.connected
    m.disconnect()
  else
    process.exit(0)

server.listen 10138, ->
  console.log 'server on'
