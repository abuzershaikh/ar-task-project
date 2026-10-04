const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const script = `
const admin = require('firebase-admin');
const mysql = require('mysql2/promise');
const serviceAccount = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey: '-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDF8/ApjOVJ3UFM\\n69V4PIx126TIAIyxjGNqX+S05FqKWffISMEDWXxF40Toajbg5ycynPxa32jyonSH\\n4vmchbB1PURb+0W4IpbkGhVJkCurbu/LBrvauPN4xCTOZbd7bK7h9MHnqxODqxHH\\nIVj8s22Hc/8xtzk6MXsUrB4tF2gLSKsx4xvBc/ywQtdRazj3z0wVE5EJ/oq3xrAg\\nAr3IbwyPbdc3a5qg0CV5gQjbcyONJypVF1regKgki3jeTA9nFV/FsQvBmzD/CI1S\\nXW5ZTD7E6ciyv6uTnsWxlqxOVaJ6kuYEx8mUPqc5k44mx5jm/AiEK3sTfK25xazH\\nHdLqPhyLAgMBAAECggEAFDpmO0i7kX27k4mx6bR+Qfjs8MclmWsYKaGc9GM1YVfq\\nOxw8JQR674VW4E0iSH82gTSLkRmtVsYFFHG8QiNjMcfN+XxG1pcqRiroK/lAjScr\\n99o7ThGCR7/7Zt/8DO/BOzPQsMTJnLXZfjjJKCGJusK+vCzV+z1dL3KbLs5qgmR/\\nUjerQR2cvcGByCo8ZRLydflCYk6D1I454vKYivMlyiJVo8etcEgmmyJeDrN+8/iy\\nsrB06BoA3bb2VoLRo8PK8hOBcpcUQNo0dXGVWt/corSDorJvSU/l+UXEu7NuXwt3\\nnRPFlGAgiR/ScaL9EdfTaKhkvmcYjaIP2Eo8zBJh8QKBgQD8g2PaHayel1ZlEwVJ\\nZydfn9dAbTAUJbSfjjwn1v9FjqACHr2t/AmcBUbEWOD4MnpJhGUIcOqvETPGHbyM\\nEWed1mJ6LCY2EQI4xf4WGmdTpd23Whi+XynnyKrlog9hvdAnbmpCvSGc1BLwrgzj\\nFGyDLEQwLAGNColvXZgswDWduQKBgQDIr663FBeSQwoNCJ0JUU1iRhNI3oVeo2xM\\nsUFs8aO8joDajvBQkXLnDwtRlKtCRaBGtgwN1EO2MNJJiTQIQzy78DUDfmy6tm0v\\nSpVxOmAQN5UiKF6uEKt7IIy+7u81mGn1WDHshBj99qIUVk8xCBTEb6ZBM9zfmIsy\\nWfX9/vIOYwKBgQCReymGOt5/KHXwGbtMBRBcOX0Mc1vl36tm2c2yrl24N2ncjtV9\\nbd4jc67H5OUIWhy2Sn7jFBtB7clEdVFx6X0nJKLr/I+vSrFbAEdZeLDbMo7A2jmz\\nRKSiE6zSTEJMb82DSkwSU2EQN+cJn11xXwz9rf1DO7dRCScRcH0CG2NIkQKBgB8W\\nV9I0YpJdoCj0tJ7E4V/fywz2q2JFnnki3CesJtkGmh9BFSjl3w673dz9UqopbvKF\\nMMjToMmQNoL9pfnBsJ7MTuoDo4QozjENNKkdidP5SDjKWCBOpMGmASdyi8uZmJBQ\\n4SrqK5Trp5/O3uWRguYLBY4EIqrgTm+2T8zQuV5RAoGAUcKd5uS51HKj2dLofgWY\\n6La/TwMSvpuxhf9ysq1WduCt54/hXAhuU9uRGPTDwfi3q7PiCd7sgS8HdBkMY+D/\\nCifUklpxWwlYynnTT6rrlNVbLnMpkyy+TM2/NZUXv4UhqnUIuVsC2CoUsFwUDw9+\\nYn5YnkjDjmTC6EJTTmvmEJY=\\n-----END PRIVATE KEY-----\\n',
};

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

async function run() {
  const pool = await mysql.createPool({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
  });

  const snap = await admin.firestore().collection('users').get();
  console.log('Total Firestore users:', snap.docs.length);

  let updatedConvs = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const fUid = doc.id;
    const email = (data.email || '').trim().toLowerCase();
    const name = (data.name || data.fullName || (email ? email.split('@')[0] : '')).trim();
    const photo = data.photoUrl || data.avatarUrl || '';

    if (name && name !== 'Worker') {
      const [cRes] = await pool.query(
        'UPDATE support_conversations SET worker_name = ?, worker_email = COALESCE(NULLIF(worker_email, \\'\\'), ?), worker_avatar_url = COALESCE(NULLIF(worker_avatar_url, \\'\\'), ?) WHERE (worker_id = ? OR (worker_email != \\'\\' AND worker_email = ?)) AND (worker_name = \\'Worker\\' OR worker_name = \\'\\' OR worker_name IS NULL)',
        [name, email, photo, fUid, email]
      );
      if (cRes.affectedRows > 0) updatedConvs += cRes.affectedRows;
    }
  }

  console.log('Sync finished. Updated conversations:', updatedConvs);

  const [check] = await pool.query('SELECT COUNT(*) as still_worker FROM support_conversations WHERE worker_name = \\'Worker\\'');
  console.log('Still worker:', check[0].still_worker);

  const [samples] = await pool.query('SELECT id, worker_id, worker_name, worker_email FROM support_conversations ORDER BY last_message_at DESC LIMIT 10');
  console.log('Recent 10 conversations:\\n', samples);

  await pool.end();
}

run().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
    `;

    await ssh.execCommand("cat << 'EOF' > /root/sync_firestore_chat.js\n" + script + "\nEOF");
    const res = await ssh.execCommand('NODE_PATH=/opt/task-engine/node_modules node /root/sync_firestore_chat.js');
    console.log(res.stdout, res.stderr);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
