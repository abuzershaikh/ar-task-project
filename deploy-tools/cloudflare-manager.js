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

async function run() {
  console.log('--- Checking Cloudflare Zones ---');
  const zonesRes = await api('/zones');
  if (zonesRes.success) {
    console.log(`Found ${zonesRes.result.length} zones:`);
    zonesRes.result.forEach(z => {
      console.log(`- ${z.name} (Status: ${z.status}, ID: ${z.id})`);
      console.log(`  Nameservers: ${z.name_servers ? z.name_servers.join(', ') : 'none'}`);
    });
  } else {
    console.log('Error fetching zones:', zonesRes.errors);
  }

  console.log('\n--- Checking Pages Project Domains ---');
  const domainsRes = await api(`/accounts/${accountId}/pages/projects/reviewsgateway/domains`);
  console.log('Current Custom Domains for reviewsgateway:', JSON.stringify(domainsRes, null, 2));
}

run().catch(console.error);
