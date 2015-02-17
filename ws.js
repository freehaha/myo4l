// Generated by CoffeeScript 1.8.0
(function() {
  var Arm, Myo, Pose, Quat, Vector3, WS, app, commands, express, getTimestamp, http, m, myo, sendEvent, server, verifyClient, wss;

  myo = require('./');

  Myo = myo.Myo;

  Quat = myo.Quaternion;

  Vector3 = myo.Vector3;

  WS = require('ws').Server;

  Pose = myo.Pose;

  Arm = myo.Arm;

  express = require('express');

  http = require('http');

  m = new Myo(process.argv[2] || 'Myo');

  m.connect();

  app = express();

  server = http.createServer(app);

  wss = new WS({
    server: server,
    path: '/myo/3',
    verifyClient: verifyClient
  });

  verifyClient = function(info, cb) {
    console.log(info);
    return cb(true);
  };

  getTimestamp = function() {
    return new Date().getTime().toString();
  };

  commands = {
    'request_rssi': function(ws, cmd) {
      return m.requestRssi();
    },
    'set_stream_emg': function(ws, cmd) {
      return m.setStreamEmg(cmd.type);
    },
    'set_locking_policy': function(ws, cmd) {
      return m.setLockingPolicy(cmd.type);
    },
    'unlock': function(ws, cmd) {
      return m.unlock(cmd.type);
    },
    'lock': function(ws, cmd) {
      return m.lock();
    },
    'vibrate': function(ws, cmd) {
      return m.vibrate(cmd.type);
    }
  };

  sendEvent = function(ws, type, data) {
    var e;
    data.type = type;
    data.timestamp = getTimestamp();
    try {
      return ws.send(JSON.stringify(['event', data]));
    } catch (_error) {
      e = _error;
      console.error(e);
      return ws.close();
    }
  };

  m.on('connected', function() {
    return wss.on('connection', function(ws) {
      var sendArm, sendEmg, sendImu, sendPose;
      ws.on('message', function(message) {
        var cmd;
        cmd = JSON.parse(message);
        if (cmd[0] === 'command' && cmd[1].command in commands) {
          return commands[cmd[1].command](ws, cmd[1]);
        }
      });
      if (m.connected) {
        sendEvent(ws, 'connected', {
          myo: 0,
          version: m.version
        });
      } else {
        m.once('connected', function() {
          return sendEvent(ws, 'connected', {
            myo: 0,
            version: m.version
          });
        });
      }
      sendImu = function(data) {
        return sendEvent(ws, 'orientation', {
          myo: 0,
          orientation: new Quat(data[0]),
          accelerometer: Vector3.parse(data[1], Vector3.ACCEL),
          gyroscope: Vector3.parse(data[2], Vector3.GYRO)
        });
      };
      sendPose = function(pose) {
        return sendEvent(ws, 'pose', {
          myo: 0,
          pose: new Pose(pose).toString()
        });
      };
      sendArm = function(arm) {
        if (arm[0] !== Arm.Arm.UNKNOWN) {
          arm = new Arm(arm);
          return sendEvent(ws, 'arm_synced', {
            myo: 0,
            arm: arm.armString(),
            x_direction: arm.xdirString()
          });
        } else {
          return sendEvent(ws, 'arm_unsynced', {
            myo: 0
          });
        }
      };
      sendEmg = function(data) {
        var emg;
        emg = [data.readInt8(0), data.readInt8(1), data.readInt8(2), data.readInt8(3), data.readInt8(4), data.readInt8(5), data.readInt8(6), data.readInt8(7)];
        return sendEvent(ws, 'emg', {
          myo: 0,
          emg: emg
        });
      };
      m.poseStream.addListener('pose', sendPose);
      m.poseStream.addListener('arm', sendArm);
      m.imuStream.addListener('data', sendImu);
      m.emgStream.addListener('data', sendEmg);
      return ws.on('close', function() {
        m.emgStream.removeListener('data', sendEmg);
        m.imuStream.removeListener('data', sendImu);
        m.poseStream.removeListener('pose', sendPose);
        return m.poseStream.removeListener('arm', sendArm);
      });
    });
  });

  m.on('disconnected', function() {
    console.log('disconnected, try to reconnect...');
    return m.connect();
  });

  process.on('SIGINT', function() {
    wss.close();
    console.log('shutting down..');
    if (m.connected) {
      m.disconnect();
    }
    return process.exit(0);
  });

  server.listen(10138, function() {
    return console.log('server on');
  });

}).call(this);
