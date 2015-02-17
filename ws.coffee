myo = require('./')
Myo = myo.Myo
Quat = myo.Quaternion
Vector3 = myo.Vector3
WS = require('ws').Server
Pose = myo.Pose
Arm = myo.Arm
express = require('express')
http = require('http')

m = new Myo(process.argv[2] || 'Myo')
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

commands = {
  'request_rssi': (ws, cmd)->
    m.requestRssi()
  'set_stream_emg': (ws, cmd)->
    m.setStreamEmg(cmd.type)
  'set_locking_policy': (ws, cmd)->
    m.setLockingPolicy(cmd.type)
  'unlock': (ws, cmd)->
    m.unlock(cmd.type)
  'lock': (ws, cmd)->
    m.lock()
  'vibrate': (ws, cmd)->
    m.vibrate cmd.type
}

sendEvent = (ws, type, data)->
  data.type = type
  data.timestamp = getTimestamp()
  try
    ws.send JSON.stringify [
      'event'
      data
    ]
  catch e
    console.error e
    ws.close()

m.on 'connected', ->
  wss.on 'connection', (ws)->
    ws.on 'message', (message)->
      cmd = JSON.parse(message)
      if cmd[0] is 'command' and cmd[1].command of commands
        commands[cmd[1].command](ws, cmd[1])
    if m.connected
      sendEvent(ws, 'connected', {
        myo: 0
        version: m.version
      })
    else
      m.once 'connected', ->
        sendEvent(ws, 'connected', {
          myo: 0
          version: m.version
        })

    sendImu = (data)->
      sendEvent(ws, 'orientation', {
        myo: 0
        orientation: new Quat(data[0])
        accelerometer: Vector3.parse(data[1], Vector3.ACCEL)
        gyroscope: Vector3.parse(data[2], Vector3.GYRO)
      })
    sendPose = (pose)->
      sendEvent(ws, 'pose', {
        myo: 0
        pose: new Pose(pose).toString()
      })
    sendArm = (arm)->
      if arm[0] != Arm.Arm.UNKNOWN
        arm = new Arm(arm)
        sendEvent ws, 'arm_synced', {
          myo: 0
          arm: arm.armString()
          x_direction: arm.xdirString()
        }
      else
        sendEvent ws, 'arm_unsynced', {
          myo: 0
        }
    sendEmg = (data)->
      emg = [
        data.readInt8(0)
        data.readInt8(1)
        data.readInt8(2)
        data.readInt8(3)
        data.readInt8(4)
        data.readInt8(5)
        data.readInt8(6)
        data.readInt8(7)
      ]
      sendEvent ws, 'emg', {
        myo: 0
        emg: emg
      }

    # set reporters
    m.poseStream.addListener 'pose', sendPose
    m.poseStream.addListener 'arm', sendArm
    m.imuStream.addListener 'data', sendImu
    m.emgStream.addListener 'data', sendEmg
    ws.on 'close', ->
      # cleanup
      m.emgStream.removeListener 'data', sendEmg
      m.imuStream.removeListener 'data', sendImu
      m.poseStream.removeListener 'pose', sendPose
      m.poseStream.removeListener 'arm', sendArm

m.on 'disconnected', ->
  console.log 'disconnected, try to reconnect...'
  m.connect()

process.on 'SIGINT', ->
  wss.close()
  console.log 'shutting down..'
  if m.connected
    m.disconnect()
  process.exit(0)

server.listen 10138, ->
  console.log 'server on'
