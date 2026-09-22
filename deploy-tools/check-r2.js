const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
if (!fs.existsSync(configPath)) {
  console.error('default.toml not found at', configPath);
  process.exit(1);
}
const content = fs.readFileSync(configPath, 'utf8');
const match = content.match(/oauth_token\s*=\s*"([^"]+)"/);
if (!match) {
  console.error('No OAuth token found in default.toml');
  process.exit(1);
}

const token = match[1];
const accountId = '46861dedb6bea0e30431beff8a2803d7';

async function main() {
  console.log('--- Checking Cloudflare Account ---');
  const accRes = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  }).then(r => r.json());
  console.log('Account Name:', accRes.result?.name || accRes);

  console.log('--- Checking R2 Buckets ---');
  const r2Res = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/r2/buckets`, {
    headers: { 'Authorization': `Bearer ${token}` }
  }).then(r => r.json());
  console.log('R2 Buckets:', JSON.stringify(r2Res.result?.buckets || r2Res, null, 2));

  console.log('--- Checking Workers Scripts ---');
  const scriptsRes = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/workers/scripts`, {
    headers: { 'Authorization': `Bearer ${token}` }
  }).then(r => r.json());
  console.log('Workers:', scriptsRes.result?.map(s => s.id) || scriptsRes);
}

main().catch(console.error);
