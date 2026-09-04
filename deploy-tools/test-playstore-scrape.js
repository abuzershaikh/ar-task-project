const https = require('https');

function extractPackageId(input) {
  if (!input) return null;
  input = input.trim();
  if (input.includes('id=')) {
    const match = input.match(/id=([a-zA-Z0-9_.]+)/);
    if (match) return match[1];
  }
  if (input.startsWith('market://details?id=')) {
    return input.replace('market://details?id=', '').split('&')[0];
  }
  if (/^[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+$/.test(input)) {
    return input;
  }
  const urlMatch = input.match(/([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)/);
  return urlMatch ? urlMatch[1] : input;
}

function fetchPlayStoreMetadata(packageId) {
  return new Promise((resolve) => {
    const url = `https://play.google.com/store/apps/details?id=${packageId}&hl=en&gl=US`;
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      },
      timeout: 10000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 400) {
          // Extract og:title
          const titleMatch = data.match(/<meta\s+property=["']og:title["']\s+content=["'](.*?)["']/i) ||
                             data.match(/<title>(.*?)<\/title>/i);
          let title = titleMatch ? titleMatch[1] : '';
          title = title.replace(/\s*-\s*Apps on Google Play.*/i, '').replace(/\s*-\s*Google Play.*/i, '').trim();

          // Extract og:image (icon)
          const iconMatch = data.match(/<meta\s+property=["']og:image["']\s+content=["'](.*?)["']/i) ||
                            data.match(/<img[^>]+src=["'](https:\/\/play-lh\.googleusercontent\.com\/[^"']+)["'][^>]*alt=["']Icon image["']/i);
          let iconUrl = iconMatch ? iconMatch[1] : '';

          // Extract description
          const fullBlock = data.match(/data-g-id=["']description["'][^>]*>([\s\S]*?)<\/div>/i) ||
                            data.match(/itemprop=["']description["'][^>]*>([\s\S]*?)<\/div>/i);
          const metaDescMatch = data.match(/<meta[^>]+content=["']([^"']*)["'][^>]+(?:name|property)=["'](?:og:)?description["']/i) ||
                                data.match(/<meta[^>]+(?:name|property)=["'](?:og:)?description["'][^>]+content=["']([^"']*)["']/i);
          
          let rawDesc = (fullBlock && fullBlock[1]) ? fullBlock[1] : (metaDescMatch ? metaDescMatch[1] : '');
          let shortDesc = metaDescMatch ? metaDescMatch[1].replace(/&amp;/g, '&').replace(/&#39;/g, "'").replace(/&quot;/g, '"').trim() : '';
          let description = rawDesc
            .replace(/<br\s*\/?>/gi, '\n')
            .replace(/<[^>]+>/g, ' ')
            .replace(/&amp;/g, '&')
            .replace(/&#39;/g, "'")
            .replace(/&quot;/g, '"')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/\s+/g, ' ')
            .trim();

          resolve({
            success: true,
            packageId,
            title,
            iconUrl,
            shortDescription: shortDesc || (description.length > 200 ? description.substring(0, 197) + '...' : description),
            description,
            playStoreUrl: `https://play.google.com/store/apps/details?id=${packageId}`
          });
        } else {
          resolve({ success: false, statusCode: res.statusCode, error: `HTTP ${res.statusCode}` });
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, error: 'Request timeout' });
    });
  });
}

async function test() {
  const testInputs = [
    'https://play.google.com/store/apps/details?id=com.spotify.music',
    'com.whatsapp',
    'https://play.google.com/store/apps/details?id=com.instagram.android&hl=en'
  ];

  for (const input of testInputs) {
    const pkg = extractPackageId(input);
    console.log(`\nTesting input: ${input} -> Package: ${pkg}`);
    const result = await fetchPlayStoreMetadata(pkg);
    console.log('Result:', JSON.stringify(result, null, 2));
  }
}

test();
