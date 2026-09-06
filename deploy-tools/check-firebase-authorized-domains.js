const { google } = require('googleapis');
const https = require('https');

const sa = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey: '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDF8/ApjOVJ3UFM\n69V4PIx126TIAIyxjGNqX+S05FqKWffISMEDWXxF40Toajbg5ycynPxa32jyonSH\n4vmchbB1PURb+0W4IpbkGhVJkCurbu/LBrvauPN4xCTOZbd7bK7h9MHnqxODqxHH\nIVj8s22Hc/8xtzk6MXsUrB4tF2gLSKsx4xvBc/ywQtdRazj3z0wVE5EJ/oq3xrAg\nAr3IbwyPbdc3a5qg0CV5gQjbcyONJypVF1regKgki3jeTA9nFV/FsQvBmzD/CI1S\nXW5ZTD7E6ciyv6uTnsWxlqxOVaJ6kuYEx8mUPqc5k44mx5jm/AiEK3sTfK25xazH\nHdLqPhyLAgMBAAECggEAFDpmO0i7kX27k4mx6bR+Qfjs8MclmWsYKaGc9GM1YVfq\nOxw8JQR674VW4E0iSH82gTSLkRmtVsYFFHG8QiNjMcfN+XxG1pcqRiroK/lAjScr\n99o7ThGCR7/7Zt/8DO/BOzPQsMTJnLXZfjjJKCGJusK+vCzV+z1dL3KbLs5qgmR/\nUjerQR2cvcGByCo8ZRLydflCYk6D1I454vKYivMlyiJVo8etcEgmmyJeDrN+8/iy\nsrB06BoA3bb2VoLRo8PK8hOBcpcUQNo0dXGVWt/corSDorJvSU/l+UXEu7NuXwt3\nnRPFlGAgiR/ScaL9EdfTaKhkvmcYjaIP2Eo8zBJh8QKBgQD8g2PaHayel1ZlEwVJ\nZydfn9dAbTAUJbSfjjwn1v9FjqACHr2t/AmcBUbEWOD4MnpJhGUIcOqvETPGHbyM\nEWed1mJ6LCY2EQI4xf4WGmdTpd23Whi+XynnyKrlog9hvdAnbmpCvSGc1BLwrgzj\nFGyDLEQwLAGNColvXZgswDWduQKBgQDIr663FBeSQwoNCJ0JUU1iRhNI3oVeo2xM\nsUFs8aO8joDajvBQkXLnDwtRlKtCRaBGtgwN1EO2MNJJiTQIQzy78DUDfmy6tm0v\nSpVxOmAQN5UiKF6uEKt7IIy+7u81mGn1WDHshBj99qIUVk8xCBTEb6ZBM9zfmIsy\nWfX9/vIOYwKBgQCReymGOt5/KHXwGbtMBRBcOX0Mc1vl36tm2c2yrl24N2ncjtV9\nbd4jc67H5OUIWhy2Sn7jFBtB7clEdVFx6X0nJKLr/I+vSrFbAEdZeLDbMo7A2jmz\nRKSiE6zSTEJMb82DSkwSU2EQN+cJn11xXwz9rf1DO7dRCScRcH0CG2NIkQKBgB8W\nV9I0YpJdoCj0tJ7E4V/fywz2q2JFnnki3CesJtkGmh9BFSjl3w673dz9UqopbvKF\nMMjToMmQNoL9pfnBsJ7MTuoDo4QozjENNKkdidP5SDjKWCBOpMGmASdyi8uZmJBQ\n4SrqK5Trp5/O3uWRguYLBY4EIqrgTm+2T8zQuV5RAoGAUcKd5uS51HKj2dLofgWY\n6La/TwMSvpuxhf9ysq1WduCt54/hXAhuU9uRGPTDwfi3q7PiCd7sgS8HdBkMY+D/\nCifUklpxWwlYynnTT6rrlNVbLnMpkyy+TM2/NZUXv4UhqnUIuVsC2CoUsFwUDw9+\nYn5YnkjDjmTC6EJTTmvmEJY=\n-----END PRIVATE KEY-----\n',
};

async function getAccessToken() {
  const jwt = new google.auth.JWT(
    sa.clientEmail,
    null,
    sa.privateKey,
    ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']
  );
  const tokens = await jwt.authorize();
  return tokens.access_token;
}

async function checkDomains() {
  try {
    const token = await getAccessToken();
    console.log('Access token obtained!');

    // Fetch Identity Platform / Firebase Auth config
    const res = await fetch(`https://identitytoolkit.googleapis.com/admin/v2/projects/${sa.projectId}/config`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    const data = await res.json();
    console.log('Identity Toolkit Config Status:', res.status);
    console.log('Authorized Domains:', data.authorizedDomains);

    // If reviewsgateway.in is not present, add it!
    const domains = data.authorizedDomains || [];
    let updated = false;

    if (!domains.includes('reviewsgateway.in')) {
      domains.push('reviewsgateway.in');
      updated = true;
    }
    if (!domains.includes('www.reviewsgateway.in')) {
      domains.push('www.reviewsgateway.in');
      updated = true;
    }
    if (!domains.includes('65.20.77.112')) {
      domains.push('65.20.77.112');
      updated = true;
    }

    if (updated) {
      console.log('Updating authorized domains to:', domains);
      const updateRes = await fetch(`https://identitytoolkit.googleapis.com/admin/v2/projects/${sa.projectId}/config?updateMask=authorizedDomains`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          authorizedDomains: domains,
        }),
      });
      const updateData = await updateRes.json();
      console.log('Update result status:', updateRes.status);
      console.log('Updated Authorized Domains:', updateData.authorizedDomains);
    } else {
      console.log('All domains are already authorized!');
    }
  } catch (e) {
    console.error('Error:', e.message);
  }
}

checkDomains();
