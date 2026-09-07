const fs = require('fs');
const path = require('path');

const configPath = path.join(process.env.APPDATA, 'xdg.config', '.wrangler', 'config', 'default.toml');
const content = fs.readFileSync(configPath, 'utf8');
const token = content.match(/oauth_token\s*=\s*"([^"]+)"/)[1];
const zoneId = 'bfd6283977a9483722ab288dd75cf5b4';

async function checkSsl() {
  const res = await fetch(`https://api.cloudflare.com/client/v4/zones/${zoneId}/settings/ssl`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  const data = await res.json();
  console.log('SSL Settings:', JSON.stringify(data, null, 2));
}

checkSsl().catch(console.error);
