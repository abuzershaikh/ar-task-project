const https = require('https');
const http = require('http');
const { URL } = require('url');

async function inspectDesc(inputUrl) {
  console.log('Inspecting:', inputUrl);
  // Follow redirects up to 8 hops
  let currentUrl = inputUrl;
  let finalBody = '';
  let finalUrl = currentUrl;

  for (let hop = 0; hop < 8; hop++) {
    const parsed = new URL(currentUrl);
    const client = parsed.protocol === 'https:' ? https : http;

    const res = await new Promise((resolve) => {
      const req = client.get(currentUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        timeout: 6000,
      }, (r) => {
        let body = '';
        r.on('data', chunk => {
          body += chunk;
          if (body.length > 500000) req.destroy();
        });
        r.on('end', () => resolve({ statusCode: r.statusCode, headers: r.headers, body }));
        r.on('close', () => resolve({ statusCode: r.statusCode, headers: r.headers, body }));
      });
      req.on('error', () => resolve({ statusCode: 500, headers: {}, body: '' }));
    });

    finalUrl = currentUrl;
    finalBody = res.body || '';

    if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
      currentUrl = new URL(res.headers.location, currentUrl).toString();
      continue;
    }
    break;
  }

  console.log('Final URL:', finalUrl);

  // Check meta description
  const metaDesc = finalBody.match(/<meta[^>]+(?:name|property)=["'](?:description|og:description)["'][^>]+content=["']([^"']+)["']/i) ||
                   finalBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+(?:name|property)=["'](?:description|og:description)["']/i);
  console.log('meta description:', metaDesc ? metaDesc[1] : null);

  // Check itemprop description
  const itemDesc = finalBody.match(/itemprop=["']description["'][^>]+content=["']([^"']+)["']/i);
  console.log('itemprop description:', itemDesc ? itemDesc[1] : null);

  // Check embedded JSON or schema
  const schemaMatch = finalBody.match(/<script type=["']application\/ld\+json["']>([^<]+)<\/script>/i);
  if (schemaMatch && schemaMatch[1]) {
    console.log('ld+json snippet:', schemaMatch[1].substring(0, 300));
  } else {
    console.log('No ld+json');
  }

  // Look for address or subtitle or category
  const addrMatch = finalBody.match(/data-attrid=["']subtitle["'][^>]*>([^<]+)/i) ||
                    finalBody.match(/data-attrid=["']kc:\/location\/location:address["'][^>]*>([^<]+)/i);
  console.log('data-attrid subtitle/address:', addrMatch ? addrMatch[1] : null);

  // Look for any snippet text in search
  const snippetMatch = finalBody.match(/<div[^>]+class=["'][^"']*BNeawe[^"']*["'][^>]*>([^<]+)<\/div>/i);
  console.log('BNeawe snippet:', snippetMatch ? snippetMatch[1] : null);
}

async function main() {
  await inspectDesc('https://share.google/rhI6QKATqwd8F3YY0');
  console.log('------------------------');
  await inspectDesc('https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z');
}

main().catch(console.error);
