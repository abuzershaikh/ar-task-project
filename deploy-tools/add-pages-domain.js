const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
const content = fs.readFileSync(configPath, 'utf8');
const match = content.match(/oauth_token\s*=\s*"([^"]+)"/);

const token = match[1];
const accountId = '46861dedb6bea0e30431beff8a2803d7';

async function addDomain(domain) {
  console.log(`Adding ${domain} to Pages project reviewsgateway...`);
  const res = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/pages/projects/reviewsgateway/domains`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ name: domain })
  });
  const data = await res.json();
  console.log(domain, 'Result:', JSON.stringify(data, null, 2));
}

async function main() {
  await addDomain('www.reviewsgateway.in');
  await addDomain('reviewsgateway.in');
}

main().catch(console.error);
