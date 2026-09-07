const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
const content = fs.readFileSync(configPath, 'utf8');
const token = content.match(/oauth_token\s*=\s*"([^"]+)"/)[1];
const accountId = '46861dedb6bea0e30431beff8a2803d7';

async function retry(domain) {
  const res = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/pages/projects/reviewsgateway/domains/${domain}/retry`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  const data = await res.json();
  console.log(`Retry ${domain}:`, JSON.stringify(data, null, 2));
}

async function main() {
  await retry('www.reviewsgateway.in');
  await retry('reviewsgateway.in');
}

main().catch(console.error);
