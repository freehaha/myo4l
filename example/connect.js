var myo = require('..')
var Myo = myo.Myo;
var Pose = myo.Pose;
var MYO_NAME = 'FreeMyo';
var m = new Myo(MYO_NAME);

m.once('connected', function() {
  m.vibrate('short');
  m.poseStream.on('pose', function(pose) {
    pose = new Pose(pose)
    console.log('pose: ', pose.toString());
    if(pose.toString() === 'thumb_to_pinky') {
      console.log('disconnecting.');
      m.disconnect();
      process.exit(0);
    }
  });
})
m.connect();

