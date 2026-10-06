const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const remoteScript = `
const admin = require('./src/config/firebase');
const uids = [
  'nSr3UuyZtPXnOBchfCxOywdEwkF2',
  'CKQx2bgrRvSkotkBAPlJXyKhKmM2',
  'i692mXZWuRNg4d34S8UFRAQN0nQ2',
  'o3jQzywZjiTv57ZqoFvSf9PE84q2',
  'oytvgDlkE8eBXliNZrLsqlxCW552',
  '0LSkjBAdF5NQ6Sw9M3WFLfiPvxJ3',
  'tRNaS3tuvNbFKM9GH0zKWQmKjc83',
  'UyF0aZf7erQW6ufAfD41gJcbl5p2',
  'yDo8Phq7BBWvBu55vYIbEGpPyy13',
  'aZlobjcdEPQZfUUsSkCdDjWjmyS2',
  'HgiCGmKr1Ha3RbKYUf9ZJYXraqo1',
  'OF7kY8WsXhPpynPJklziWtIYAf82',
  '6xPoRuO0KwMIv0XCIXIK9G3t8Mv2'
];

async function check() {
  for (const uid of uids) {
    try {
      const u = await admin.auth().getUser(uid);
      console.log('FIREBASE SUCCESS:', uid, '=> name:', u.displayName, '| email:', u.email, '| phone:', u.phoneNumber);
    } catch (e) {
      console.log('FIREBASE NOT FOUND for', uid, ':', e.message);
    }
  }
}
check().then(() => process.exit(0));
`;

  await ssh.execCommand(`cat << 'EOF' > /opt/support-chat-engine/test_fb.js\n${remoteScript}\nEOF`);
  const res = await ssh.execCommand('node test_fb.js', { cwd: '/opt/support-chat-engine' });
  console.log(res.stdout);
  console.log(res.stderr);

  ssh.dispose();
}

main().catch(console.error);
