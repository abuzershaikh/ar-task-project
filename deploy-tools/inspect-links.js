const fs = require('fs');
const html = fs.readFileSync('deploy-tools/downloaded_reviewsgateway.html', 'utf8');
const header = fs.readFileSync('deploy-tools/downloaded_site/components/header.html', 'utf8');
const footer = fs.readFileSync('deploy-tools/downloaded_site/components/footer.html', 'utf8');

const allText = html + header + footer;
const hrefs = new Set([...allText.matchAll(/href=["']([^"']+)["']/gi)].map(m => m[1]));
console.log('Unique hrefs count:', hrefs.size);
console.log('Unique hrefs:\n', Array.from(hrefs).filter(h => !h.includes('font') && !h.includes('cloudinary')).join('\n'));
