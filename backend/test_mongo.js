const mongoose = require('mongoose');

const passwords = [
  '01747729757%40Sk',
  '01747729757',
  'db_01747729757%40Sk',
  'db_01747729757',
  'db_01747729757@Sk',
  'db_01747729757\\@Sk'
];

async function test(pass) {
  const uri = `mongodb+srv://kuakata_admin:${pass}@kuakatacluster.t4xlvyq.mongodb.net/?appName=KuakataCluster`;
  console.log(`Testing with password: ${decodeURIComponent(pass)}...`);
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
    console.log(`SUCCESS: Connected with password: ${decodeURIComponent(pass)}`);
    await mongoose.disconnect();
    return true;
  } catch (err) {
    console.log(`FAILED: ${err.message}`);
    return false;
  }
}

async function run() {
  for (const pass of passwords) {
    const success = await test(pass);
    if (success) {
      console.log(`FOUND WORKING CONNECTION: ${pass}`);
      break;
    }
  }
  process.exit(0);
}

run();
