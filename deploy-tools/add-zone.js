const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
const content = fs.readFileSync(configPath, 'utf8');
const match = content.match(/oauth_token\s*=\s*"([^"]+)"/);

if (!match) {
  console.error('No OAuth token found in default.toml');
  process.exit(1);
}

const token = match[1];
const accountId = '46861dedb6bea0e30431beff8a2803d7';

async function api(endpoint, method = 'GET', body = null) {
  const opts = {
    method,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  };
  if (body) {
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(`https://api.cloudflare.com/client/v4${endpoint}`, opts);
  return await res.json();
}

async function addZone() {
  console.log('--- Adding Zone reviewsgateway.in ---');
  const zoneRes = await api('/zones', 'POST', {
    account: { id: accountId },
    name: 'reviewsgateway.in',
    type: 'full'
  });
  console.log('Zone creation response:', JSON.stringify(zoneRes, null, 2));

  if (zoneRes.success) {
    const zone = zoneRes.result;
    console.log('\n========================================');
    console.log('Zone Created Successfully!');
    console.log('Zone ID:', zone.id);
    console.log('Nameservers to set on Bluehost:');
    console.log(zone.name_servers.join('\n'));
    console.log('========================================\n');
    return zone;
  }
  return null;
}

addZone().catch(console.error);
