const { URL } = require('url');

function extractDetails(urlString, htmlBody) {
  let name = '';
  let address = '';
  let category = '';
  let description = '';

  try {
    const parsed = new URL(urlString);
    
    // Check place URL e.g. /maps/place/Name,+Address/@lat,lng
    const placeMatch = urlString.match(/\/maps\/place\/([^\/@?]+)/i);
    if (placeMatch && placeMatch[1]) {
      const decoded = decodeURIComponent(placeMatch[1]).replace(/\+/g, ' ');
      const parts = decoded.split(',');
      name = parts[0].trim();
      if (parts.length > 1) {
        address = parts.slice(1).join(', ').trim();
      }
    }

    // Check search URL e.g. ?q=BABA+Caterers
    const qParam = parsed.searchParams.get('q') || parsed.searchParams.get('query');
    if (qParam && !name) {
      const decoded = decodeURIComponent(qParam).replace(/\+/g, ' ');
      const parts = decoded.split(',');
      name = parts[0].trim();
      if (parts.length > 1) {
        address = parts.slice(1).join(', ').trim();
      }
    }

    // Check for category or keywords in name
    const lowerName = (name || '').toLowerCase();
    if (lowerName.includes('cater')) category = 'Catering & Food Services';
    else if (lowerName.includes('restaurant') || lowerName.includes('hotel') || lowerName.includes('dhaba') || lowerName.includes('cafe')) category = 'Restaurant & Dining';
    else if (lowerName.includes('salon') || lowerName.includes('spa') || lowerName.includes('beauty')) category = 'Beauty & Wellness';
    else if (lowerName.includes('hospital') || lowerName.includes('clinic') || lowerName.includes('dental')) category = 'Healthcare & Medical';
    else if (lowerName.includes('store') || lowerName.includes('shop') || lowerName.includes('mart') || lowerName.includes('bazaar')) category = 'Retail & Shopping';
    else category = 'Local Business & Services';

    // Meta description in HTML
    if (htmlBody) {
      const metaMatch = htmlBody.match(/<meta[^>]+(?:name|property)=["'](?:description|og:description)["'][^>]+content=["']([^"']+)["']/i) ||
                        htmlBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+(?:name|property)=["'](?:description|og:description)["']/i);
      if (metaMatch && metaMatch[1] && !metaMatch[1].includes('Find local businesses')) {
        description = metaMatch[1].trim();
      }
    }

    if (!description && name) {
      description = address 
        ? `${category} located at ${address}. Verified Google Business Profile.`
        : `${category} • Verified Google Maps Business Profile.`;
    }
  } catch (_) {}

  return { name, address, category, description };
}

console.log(extractDetails('https://www.google.com/search?q=BABA+Caterers&kgmid=/g/11f2sg9qp5', ''));
console.log(extractDetails('https://www.google.com/maps/place/Taj+Mahal,+Dharmapuri,+Forest+Colony,+Tajganj,+Agra,+Uttar+Pradesh+282001/@27.1751448,78.0421422,17z', ''));
