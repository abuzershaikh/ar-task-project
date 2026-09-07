const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
const content = fs.readFileSync(configPath, 'utf8');
const match = content.match(/oauth_token\s*=\s*"([^"]+)"/);

const token = match[1];
const accountId = '46861dedb6bea0e30431beff8a2803d7';

async function checkDetails() {
  const res = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/pages/projects/reviewsgateway/domains/reviewsgateway.in`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  const data = await res.json();
  console.log('Root domain details:', JSON.stringify(data, null, 2));

  const resWww = await fetch(`https://api.cloudflare.com/client/v4/accounts/${accountId}/pages/projects/reviewsgateway/domains/www.reviewsgateway.in`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  const dataWww = await resWww.json();
  console.log('WWW domain details:', JSON.stringify(dataWww, null, 2));
}

checkDetails().catch(console.error);
