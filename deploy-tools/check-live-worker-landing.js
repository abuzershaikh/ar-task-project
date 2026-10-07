async function check() {
  const urls = [
    'https://taskwebsiteworker.pages.dev',
    'https://reviewsgateway.com',
  ];

  for (const url of urls) {
    try {
      console.log(`\n=== Checking: ${url} ===`);
      const res = await fetch(url);
      console.log('HTTP Status:', res.status, res.statusText);
      const html = await res.text();
      
      const apkLinks = [];
      const regex = /href=["']([^"']*\.apk[^"']*)["']/gi;
      let m;
      while ((m = regex.exec(html)) !== null) {
        apkLinks.push(m[1]);
      }
      console.log('APK links found:', apkLinks);

      const r2Links = [];
      const regexR2 = /https:\/\/[^"'\s]*r2\.dev\/[^"'\s]*/gi;
      let m2;
      while ((m2 = regexR2.exec(html)) !== null) {
        r2Links.push(m2[0]);
      }
      console.log('R2 links found:', r2Links);
    } catch (err) {
      console.error('Error fetching', url, err.message);
    }
  }
}

check();
