const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
const content = fs.readFileSync(configPath, 'utf8');
const token = content.match(/oauth_token\s*=\s*"([^"]+)"/)[1];
const zoneId = 'bfd6283977a9483722ab288dd75cf5b4';

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

async function run() {
  console.log('--- Fetching existing DNS records in Cloudflare ---');
  const records = await api(`/zones/${zoneId}/dns_records`);
  console.log('Success:', records.success);
  if (records.result) {
    console.log(`Found ${records.result.length} records:`);
    records.result.forEach(r => {
      console.log(`- Type: ${r.type}, Name: ${r.name}, Content: ${r.content}, Proxied: ${r.proxied}, ID: ${r.id}`);
    });
  } else {
    console.log('Errors:', records.errors);
  }
}

run().catch(console.error);
