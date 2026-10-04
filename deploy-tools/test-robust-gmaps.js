const https = require('https');
const http = require('http');
const { URL } = require('url');

function cleanBusinessName(raw) {
  if (!raw) return '';
  let cleaned = decodeURIComponent(raw)
    .replace(/\+/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s*-\s*Google Maps.*/i, '')
    .replace(/\s*·\s*Google Maps.*/i, '')
    .replace(/\s*\|\s*Google Maps.*/i, '')
    .replace(/Google Maps/i, '')
    .replace(/Google Search/i, '')
    .replace(/\s*,\s*India$/i, '')
    .trim();

  // If there's an address in parentheses or after a dash, keep the main brand
  cleaned = cleaned.replace(/\s*\([^)]*\)$/, '').trim();
  return cleaned;
}

function isInvalidBusinessName(name) {
  if (!name || name.trim().length <= 1) return true;
  const lower = name.trim().toLowerCase();
  return (
    lower === 'google maps' ||
    lower === 'google search' ||
    lower.includes('302 moved') ||
    lower.includes('301 moved') ||
    lower.includes('moved permanently') ||
    lower.includes('redirecting') ||
    lower === 'google' ||
    lower === 'search' ||
    lower.startsWith('http://') ||
    lower.startsWith('https://') ||
    /^[a-zA-Z0-9_\-]{15,}$/.test(name.trim()) // Raw random shortcode / token
  );
}

function extractNameFromUrl(urlString) {
  try {
    const parsed = new URL(urlString);
    
    // Ignore shortener endpoints
    if (
      parsed.hostname === 'share.google' ||
      parsed.pathname === '/share.google' ||
      parsed.hostname.includes('goo.gl')
    ) {
      return '';
    }

    // 1. /maps/place/<PlaceName>
    const placeMatch = urlString.match(/\/maps\/place\/([^\/@?]+)/i);
    if (placeMatch && placeMatch[1]) {
      const candidate = cleanBusinessName(placeMatch[1]);
      if (!isInvalidBusinessName(candidate)) return candidate;
    }

    // 2. /maps/search/<PlaceName>
    const searchMatch = urlString.match(/\/maps\/search\/([^\/@?]+)/i);
    if (searchMatch && searchMatch[1]) {
      const candidate = cleanBusinessName(searchMatch[1]);
      if (!isInvalidBusinessName(candidate)) return candidate;
    }

    // 3. ?q= or ?query= parameter (e.g. Google Search share link or Google Maps query)
    const qParam = parsed.searchParams.get('q') || parsed.searchParams.get('query');
    if (qParam) {
      // Check if qParam is just lat,lng coordinates e.g. 28.123,77.456
      if (!/^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$/.test(qParam.trim())) {
        const candidate = cleanBusinessName(qParam);
        if (!isInvalidBusinessName(candidate)) return candidate;
      }
    }
  } catch (_) {}
  return '';
}

async function resolveAndScrapeGoogleMaps(inputUrl) {
  let currentUrl = inputUrl.trim();
  if (!currentUrl.startsWith('http://') && !currentUrl.startsWith('https://')) {
    currentUrl = `https://${currentUrl}`;
  }

  let finalUrl = currentUrl;
  let candidateNames = [];
  let finalBody = '';

  const nameFromInitial = extractNameFromUrl(currentUrl);
  if (nameFromInitial) candidateNames.push(nameFromInitial);

  // Follow redirects up to 8 hops using GET
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
      req.on('timeout', () => { req.destroy(); resolve({ statusCode: 408, headers: {}, body: '' }); });
    });

    finalUrl = currentUrl;
    finalBody = res.body || '';

    const extracted = extractNameFromUrl(currentUrl);
    if (extracted && !candidateNames.includes(extracted)) {
      candidateNames.push(extracted);
    }

    // Check Location header for redirect
    if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
      const nextUrl = new URL(res.headers.location, currentUrl).toString();
      const extractedNext = extractNameFromUrl(nextUrl);
      if (extractedNext && !candidateNames.includes(extractedNext)) {
        candidateNames.push(extractedNext);
      }
      currentUrl = nextUrl;
      continue;
    }

    break;
  }

  // Parse HTML
  let htmlTitle = '';
  let ogImage = '';

  // 1. JSON title [null, "Place Name", [[...
  const jsonMatch = finalBody.match(/\[null,\s*"([^"\\]*(?:\\.[^"\\]*)*)",\s*\[\[(?:\d|\.)/);
  if (jsonMatch && jsonMatch[1]) {
    try {
      const parsedTitle = JSON.parse(`"${jsonMatch[1]}"`);
      if (!isInvalidBusinessName(parsedTitle)) htmlTitle = cleanBusinessName(parsedTitle);
    } catch (_) {
      if (!isInvalidBusinessName(jsonMatch[1])) htmlTitle = cleanBusinessName(jsonMatch[1]);
    }
  }

  // 2. og:title meta
  if (!htmlTitle) {
    const ogTitleMatch = finalBody.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i) ||
                         finalBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i);
    if (ogTitleMatch && ogTitleMatch[1]) {
      const cleanOg = cleanBusinessName(ogTitleMatch[1]);
      if (!isInvalidBusinessName(cleanOg)) htmlTitle = cleanOg;
    }
  }

  // 3. <title>
  if (!htmlTitle) {
    const rawTitleMatch = finalBody.match(/<title[^>]*>([^<]+)<\/title>/i);
    if (rawTitleMatch && rawTitleMatch[1]) {
      const cleanRaw = cleanBusinessName(rawTitleMatch[1]);
      if (!isInvalidBusinessName(cleanRaw)) htmlTitle = cleanRaw;
    }
  }

  // 4. Image
  const ogImageMatch = finalBody.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i) ||
                       finalBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i);
  if (ogImageMatch && ogImageMatch[1]) {
    ogImage = ogImageMatch[1].replace(/&amp;/g, '&');
  }
  if (!ogImage || !ogImage.startsWith('http')) {
    ogImage = 'https://maps.gstatic.com/tactile/pane/default_geocode-2x.png';
  }

  const finalBusinessName = htmlTitle || (candidateNames.length > 0 ? candidateNames[candidateNames.length - 1] : '');

  return {
    success: !!finalBusinessName,
    businessName: finalBusinessName,
    businessIcon: ogImage,
    resolvedUrl: finalUrl,
    candidates: candidateNames,
  };
}

async function test() {
  console.log('Testing share.google:');
  const res1 = await resolveAndScrapeGoogleMaps('https://share.google/rhI6QKATqwd8F3YY0');
  console.log('Result 1:', res1);
}

test().catch(console.error);
