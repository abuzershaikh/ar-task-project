const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const vpsScript = `
const admin = require('firebase-admin');
const https = require('https');

const sa = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey: '-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDF8/ApjOVJ3UFM\\n69V4PIx126TIAIyxjGNqX+S05FqKWffISMEDWXxF40Toajbg5ycynPxa32jyonSH\\n4vmchbB1PURb+0W4IpbkGhVJkCurbu/LBrvauPN4xCTOZbd7bK7h9MHnqxODqxHH\\nIVj8s22Hc/8xtzk6MXsUrB4tF2gLSKsx4xvBc/ywQtdRazj3z0wVE5EJ/oq3xrAg\\nAr3IbwyPbdc3a5qg0CV5gQjbcyONJypVF1regKgki3jeTA9nFV/FsQvBmzD/CI1S\\nXW5ZTD7E6ciyv6uTnsWxlqxOVaJ6kuYEx8mUPqc5k44mx5jm/AiEK3sTfK25xazH\\nHdLqPhyLAgMBAAECggEAFDpmO0i7kX27k4mx6bR+Qfjs8MclmWsYKaGc9GM1YVfq\\nOxw8JQR674VW4E0iSH82gTSLkRmtVsYFFHG8QiNjMcfN+XxG1pcqRiroK/lAjScr\\n99o7ThGCR7/7Zt/8DO/BOzPQsMTJnLXZfjjJKCGJusK+vCzV+z1dL3KbLs5qgmR/\\nUjerQR2cvcGByCo8ZRLydflCYk6D1I454vKYivMlyiJVo8etcEgmmyJeDrN+8/iy\\nsrB06BoA3bb2VoLRo8PK8hOBcpcUQNo0dXGVWt/corSDorJvSU/l+UXEu7NuXwt3\\nnRPFlGAgiR/ScaL9EdfTaKhkvmcYjaIP2Eo8zBJh8QKBgQD8g2PaHayel1ZlEwVJ\\nZydfn9dAbTAUJbSfjjwn1v9FjqACHr2t/AmcBUbEWOD4MnpJhGUIcOqvETPGHbyM\\nEWed1mJ6LCY2EQI4xf4WGmdTpd23Whi+XynnyKrlog9hvdAnbmpCvSGc1BLwrgzj\\nFGyDLEQwLAGNColvXZgswDWduQKBgQDIr663FBeSQwoNCJ0JUU1iRhNI3oVeo2xM\\nsUFs8aO8joDajvBQkXLnDwtRlKtCRaBGtgwN1EO2MNJJiTQIQzy78DUDfmy6tm0v\\nSpVxOmAQN5UiKF6uEKt7IIy+7u81mGn1WDHshBj99qIUVk8xCBTEb6ZBM9zfmIsy\\nWfX9/vIOYwKBgQCReymGOt5/KHXwGbtMBRBcOX0Mc1vl36tm2c2yrl24N2ncjtV9\\nbd4jc67H5OUIWhy2Sn7jFBtB7clEdVFx6X0nJKLr/I+vSrFbAEdZeLDbMo7A2jmz\\nRKSiE6zSTEJMb82DSkwSU2EQN+cJn11xXwz9rf1DO7dRCScRcH0CG2NIkQKBgB8W\\nV9I0YpJdoCj0tJ7E4V/fywz2q2JFnnki3CesJtkGmh9BFSjl3w673dz9UqopbvKF\\nMMjToMmQNoL9pfnBsJ7MTuoDo4QozjENNKkdidP5SDjKWCBOpMGmASdyi8uZmJBQ\\n4SrqK5Trp5/O3uWRguYLBY4EIqrgTm+2T8zQuV5RAoGAUcKd5uS51HKj2dLofgWY\\n6La/TwMSvpuxhf9ysq1WduCt54/hXAhuU9uRGPTDwfi3q7PiCd7sgS8HdBkMY+D/\\nCifUklpxWwlYynnTT6rrlNVbLnMpkyy+TM2/NZUXv4UhqnUIuVsC2CoUsFwUDw9+\\nYn5YnkjDjmTC6EJTTmvmEJY=\\n-----END PRIVATE KEY-----\\n'
};

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(sa) });
}

async function start() {
  const credential = admin.app().options.credential;
  const tokenObj = await credential.getAccessToken();
  const token = tokenObj.access_token;
  console.log('Got Google Cloud access token!');

  const fetchConfig = () => new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'identitytoolkit.googleapis.com',
      path: '/admin/v2/projects/' + sa.projectId + '/config',
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ' + token,
      }
    }, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.end();
  });

  const updateConfig = (domains) => new Promise((resolve, reject) => {
    const payload = JSON.stringify({ authorizedDomains: domains });
    const req = https.request({
      hostname: 'identitytoolkit.googleapis.com',
      path: '/admin/v2/projects/' + sa.projectId + '/config?updateMask=authorizedDomains',
      method: 'PATCH',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });

  const res = await fetchConfig();
  console.log('Current Firebase Auth Config status:', res.status);
  console.log('Current Authorized Domains:', res.data.authorizedDomains);

  const list = res.data.authorizedDomains || [];
  let needed = false;
  ['reviewsgateway.in', 'www.reviewsgateway.in', '65.20.77.112'].forEach(d => {
    if (!list.includes(d)) {
      list.push(d);
      needed = true;
    }
  });

  if (needed) {
    console.log('Updating domains to include reviewsgateway.in...');
    const upRes = await updateConfig(list);
    console.log('Update status:', upRes.status);
    console.log('Updated Authorized Domains:', upRes.data.authorizedDomains);
  } else {
    console.log('All domains already in authorized list!');
  }
}

start().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
`;

    const result = await ssh.execCommand(`node -e "${vpsScript.replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });
    console.log(result.stdout);
    if (result.stderr) console.error(result.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
