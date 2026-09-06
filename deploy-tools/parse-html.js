const fs = require('fs');
const html = fs.readFileSync('deploy-tools/downloaded_reviewsgateway.html', 'utf8');

const titleMatch = html.match(/<title>(.*?)<\/title>/i);
console.log('TITLE:', titleMatch ? titleMatch[1] : 'No title');

const cssMatches = [...html.matchAll(/<link[^>]+href=["']([^"']+\.css[^"']*)["'][^>]*>/gi)];
console.log('CSS files:', cssMatches.map(m => m[1]));

const jsMatches = [...html.matchAll(/<script[^>]+src=["']([^"']+\.js[^"']*)["'][^>]*>/gi)];
console.log('JS files:', jsMatches.map(m => m[1]));

const imgMatches = [...html.matchAll(/<img[^>]+src=["']([^"']+)["'][^>]*>/gi)];
console.log('Images count:', imgMatches.length);
console.log('First 10 images:', imgMatches.slice(0, 10).map(m => m[1]));

const sections = [...html.matchAll(/<(header|section|footer)[^>]*id=["']?([^"'\s>]+)?["']?[^>]*class=["']?([^"'>]+)?["']?[^>]*>/gi)];
console.log('Sections:', sections.map(s => s[0].substring(0, 100)));
