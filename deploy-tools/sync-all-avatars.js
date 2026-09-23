const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    console.log('Connecting to VPS...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected to VPS.');

    // 1. Add avatar_url column to users table if not exists
    console.log('Altering MySQL tables if needed...');
    await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500) NULL AFTER full_name;
      ALTER TABLE support_conversations ADD COLUMN IF NOT EXISTS worker_avatar_url VARCHAR(500) NULL AFTER worker_email;
    "`);

    // 2. Upload sync script to VPS
    const syncScript = `
const admin = require('firebase-admin');
const mysql = require('mysql2/promise');

const serviceAccount = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey:
    '-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDF8/ApjOVJ3UFM\\n69V4PIx126TIAIyxjGNqX+S05FqKWffISMEDWXxF40Toajbg5ycynPxa32jyonSH\\n4vmchbB1PURb+0W4IpbkGhVJkCurbu/LBrvauPN4xCTOZbd7bK7h9MHnqxODqxHH\\nIVj8s22Hc/8xtzk6MXsUrB4tF2gLSKsx4xvBc/ywQtdRazj3z0wVE5EJ/oq3xrAg\\nAr3IbwyPbdc3a5qg0CV5gQjbcyONJypVF1regKgki3jeTA9nFV/FsQvBmzD/CI1S\\nXW5ZTD7E6ciyv6uTnsWxlqxOVaJ6kuYEx8mUPqc5k44mx5jm/AiEK3sTfK25xazH\\nHdLqPhyLAgMBAAECggEAFDpmO0i7kX27k4mx6bR+Qfjs8MclmWsYKaGc9GM1YVfq\\nOxw8JQR674VW4E0iSH82gTSLkRmtVsYFFHG8QiNjMcfN+XxG1pcqRiroK/lAjScr\\n99o7ThGCR7/7Zt/8DO/BOzPQsMTJnLXZfjjJKCGJusK+vCzV+z1dL3KbLs5qgmR/\\nUjerQR2cvcGByCo8ZRLydflCYk6D1I454vKYivMlyiJVo8etcEgmmyJeDrN+8/iy\\nsrB06BoA3bb2VoLRo8PK8hOBcpcUQNo0dXGVWt/corSDorJvSU/l+UXEu7NuXwt3\\nnRPFlGAgiR/ScaL9EdfTaKhkvmcYjaIP2Eo8zBJh8QKBgQD8g2PaHayel1ZlEwVJ\\nZydfn9dAbTAUJbSfjjwn1v9FjqACHr2t/AmcBUbEWOD4MnpJhGUIcOqvETPGHbyM\\nEWed1mJ6LCY2EQI4xf4WGmdTpd23Whi+XynnyKrlog9hvdAnbmpCvSGc1BLwrgzj\\nFGyDLEQwLAGNColvXZgswDWduQKBgQDIr663FBeSQwoNCJ0JUU1iRhNI3oVeo2xM\\nsUFs8aO8joDajvBQkXLnDwtRlKtCRaBGtgwN1EO2MNJJiTQIQzy78DUDfmy6tm0v\\nSpVxOmAQN5UiKF6uEKt7IIy+7u81mGn1WDHshBj99qIUVk8xCBTEb6ZBM9zfmIsy\\nWfX9/vIOYwKBgQCReymGOt5/KHXwGbtMBRBcOX0Mc1vl36tm2c2yrl24N2ncjtV9\\nbd4jc67H5OUIWhy2Sn7jFBtB7clEdVFx6X0nJKLr/I+vSrFbAEdZeLDbMo7A2jmz\\nRKSiE6zSTEJMb82DSkwSU2EQN+cJn11xXwz9rf1DO7dRCScRcH0CG2NIkQKBgB8W\\nV9I0YpJdoCj0tJ7E4V/fywz2q2JFnnki3CesJtkGmh9BFSjl3w673dz9UqopbvKF\\nMMjToMmQNoL9pfnBsJ7MTuoDo4QozjENNKkdidP5SDjKWCBOpMGmASdyi8uZmJBQ\\n4SrqK5Trp5/O3uWRguYLBY4EIqrgTm+2T8zQuV5RAoGAUcKd5uS51HKj2dLofgWY\\n6La/TwMSvpuxhf9ysq1WduCt54/hXAhuU9uRGPTDwfi3q7PiCd7sgS8HdBkMY+D/\\nCifUklpxWwlYynnTT6rrlNVbLnMpkyy+TM2/NZUXv4UhqnUIuVsC2CoUsFwUDw9+\\nYn5YnkjDjmTC6EJTTmvmEJY=\\n-----END PRIVATE KEY-----\\n',
};

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

async function syncAvatars() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
  });

  console.log('Connected to MySQL database.');

  let updatedUsers = 0;
  let updatedConv = 0;

  // 1. Fetch from Firebase Auth
  let nextPageToken;
  do {
    const listResult = await admin.auth().listUsers(1000, nextPageToken);
    for (const u of listResult.users) {
      if (u.photoURL) {
        const [res1] = await connection.execute(
          'UPDATE users SET avatar_url = ? WHERE (id = ? OR email = ?) AND (avatar_url IS NULL OR avatar_url = \\'\\')',
          [u.photoURL, u.uid, u.email || '']
        );
        if (res1.affectedRows > 0) updatedUsers += res1.affectedRows;

        const [res2] = await connection.execute(
          'UPDATE support_conversations SET worker_avatar_url = ? WHERE (worker_id = ? OR worker_email = ?) AND (worker_avatar_url IS NULL OR worker_avatar_url = \\'\\')',
          [u.photoURL, u.uid, u.email || '']
        );
        if (res2.affectedRows > 0) updatedConv += res2.affectedRows;
      }
    }
    nextPageToken = listResult.pageToken;
  } while (nextPageToken);

  // 2. Fetch from Firestore users collection (if any user has photoUrl in firestore doc)
  const snap = await admin.firestore().collection('users').get();
  for (const doc of snap.docs) {
    const data = doc.data();
    const photo = data.photoUrl || data.photoURL || data.avatarUrl;
    if (photo && typeof photo === 'string' && photo.startsWith('http')) {
      const [res1] = await connection.execute(
        'UPDATE users SET avatar_url = ? WHERE (id = ? OR email = ?) AND (avatar_url IS NULL OR avatar_url = \\'\\')',
        [photo, doc.id, data.email || '']
      );
      if (res1.affectedRows > 0) updatedUsers += res1.affectedRows;

      const [res2] = await connection.execute(
        'UPDATE support_conversations SET worker_avatar_url = ? WHERE (worker_id = ? OR worker_email = ?) AND (worker_avatar_url IS NULL OR worker_avatar_url = \\'\\')',
        [photo, doc.id, data.email || '']
      );
      if (res2.affectedRows > 0) updatedConv += res2.affectedRows;
    }
  }

  console.log(\`✅ Sync complete! Updated \${updatedUsers} users and \${updatedConv} conversations with Gmail profile photos.\`);

  // Verify sample users with avatars
  const [sampleUsers] = await connection.query('SELECT id, email, full_name, avatar_url FROM users WHERE avatar_url IS NOT NULL LIMIT 10');
  console.log('Sample Users with Avatars in MySQL:');
  console.table(sampleUsers);

  // Verify sample conversations with avatars
  const [sampleConv] = await connection.query('SELECT worker_id, worker_name, worker_email, worker_avatar_url FROM support_conversations WHERE worker_avatar_url IS NOT NULL LIMIT 10');
  console.log('Sample Conversations with Avatars in MySQL:');
  console.table(sampleConv);

  await connection.end();
  process.exit(0);
}

syncAvatars().catch(err => {
  console.error('Error during avatar sync:', err);
  process.exit(1);
});
`;

    console.log('Uploading sync script to /opt/support-chat-engine/sync-avatars.js ...');
    await ssh.execCommand(`cat << 'EOF' > /opt/support-chat-engine/sync-avatars.js\n${syncScript}\nEOF`);

    console.log('Running sync script on VPS...');
    const result = await ssh.execCommand('node sync-avatars.js', { cwd: '/opt/support-chat-engine' });
    console.log(result.stdout);
    if (result.stderr) console.error(result.stderr);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

main();
