const https = require('https');

https.get('https://play.google.com/store/apps/details?id=com.spotify.music&hl=en&gl=US', {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    // Check all meta tags
    const metas = data.match(/<meta[^>]+>/gi) || [];
    console.log('Metas count:', metas.length);
    metas.filter(m => m.includes('description') || m.includes('About this app')).forEach(m => console.log(m));

    // Check JSON-LD
    const jsonLd = data.match(/<script type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/gi) || [];
    console.log('JSON-LD count:', jsonLd.length);
    jsonLd.forEach(j => {
      try {
        const clean = j.replace(/<script[^>]*>/, '').replace(/<\/script>/, '');
        const obj = JSON.parse(clean);
        console.log('JSON-LD name:', obj.name, '| desc:', (obj.description || '').substring(0, 150));
      } catch (e) {
        console.log('JSON-LD parse error:', e.message);
      }
    });

    // Check data-g-id or description patterns
    const descBlock = data.match(/data-g-id="description"[^>]*>([\s\S]*?)<\/div>/i) ||
                      data.match(/itemprop="description"[^>]*>([\s\S]*?)<\/div>/i);
    if (descBlock) {
      console.log('Desc block found! Length:', descBlock[1].length);
      console.log('Sample:', descBlock[1].substring(0, 200));
    }
  });
});
