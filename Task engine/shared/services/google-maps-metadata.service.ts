import { Injectable, Logger } from '@nestjs/common';
import * as https from 'https';
import * as http from 'http';
import { URL } from 'url';

export interface GoogleBusinessMetadata {
    success: boolean;
    businessName?: string;
    businessIcon?: string;
    description?: string;
    category?: string;
    address?: string;
    mapsUrl?: string;
    error?: string;
}

@Injectable()
export class GoogleMapsMetadataService {
    private readonly logger = new Logger(GoogleMapsMetadataService.name);

    /**
     * Clean and format business name extracted from Google Maps URL or HTML
     */
    private cleanBusinessName(raw: string): string {
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

    /**
     * Reject error pages, HTTP redirects or generic search terms
     */
    private isInvalidBusinessName(name: string): boolean {
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
            /^[a-zA-Z0-9_\-]{15,}$/.test(name.trim()) // Raw random shortcode or hash
        );
    }

    /**
     * Extract business / place name and address from URL paths or query params
     */
    private extractNameAndAddressFromUrl(urlString: string): { name: string; address: string } {
        let name = '';
        let address = '';

        try {
            const parsed = new URL(urlString);

            // Ignore shortener endpoints
            if (
                parsed.hostname === 'share.google' ||
                parsed.pathname === '/share.google' ||
                parsed.hostname.includes('goo.gl')
            ) {
                return { name: '', address: '' };
            }

            // 1. /maps/place/<PlaceName>,+<Address>
            const placeMatch = urlString.match(/\/maps\/place\/([^\/@?]+)/i);
            if (placeMatch && placeMatch[1]) {
                const decoded = decodeURIComponent(placeMatch[1]).replace(/\+/g, ' ');
                const parts = decoded.split(',');
                const candidate = this.cleanBusinessName(parts[0]);
                if (!this.isInvalidBusinessName(candidate)) {
                    name = candidate;
                    if (parts.length > 1) {
                        address = parts.slice(1).join(', ').trim();
                    }
                }
            }

            // 2. /maps/search/<PlaceName>
            if (!name) {
                const searchMatch = urlString.match(/\/maps\/search\/([^\/@?]+)/i);
                if (searchMatch && searchMatch[1]) {
                    const decoded = decodeURIComponent(searchMatch[1]).replace(/\+/g, ' ');
                    const parts = decoded.split(',');
                    const candidate = this.cleanBusinessName(parts[0]);
                    if (!this.isInvalidBusinessName(candidate)) {
                        name = candidate;
                        if (parts.length > 1) {
                            address = parts.slice(1).join(', ').trim();
                        }
                    }
                }
            }

            // 3. ?q= or ?query= parameter (e.g. Google Search share link or Google Maps query)
            if (!name) {
                const qParam = parsed.searchParams.get('q') || parsed.searchParams.get('query');
                if (qParam && !/^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$/.test(qParam.trim())) {
                    const decoded = decodeURIComponent(qParam).replace(/\+/g, ' ');
                    const parts = decoded.split(',');
                    const candidate = this.cleanBusinessName(parts[0]);
                    if (!this.isInvalidBusinessName(candidate)) {
                        name = candidate;
                        if (parts.length > 1) {
                            address = parts.slice(1).join(', ').trim();
                        }
                    }
                }
            }
        } catch (_) { }

        return { name, address };
    }

    /**
     * Fetch Google Maps / Google Business listing details
     */
    async getBusinessMetadata(inputUrl: string): Promise<GoogleBusinessMetadata> {
        if (!inputUrl || typeof inputUrl !== 'string') {
            return { success: false, error: 'Google Maps URL is required' };
        }

        let currentUrl = inputUrl.trim();
        if (!currentUrl.startsWith('http://') && !currentUrl.startsWith('https://')) {
            currentUrl = `https://${currentUrl}`;
        }

        this.logger.log(`Fetching Google Maps metadata for: ${currentUrl}`);

        try {
            let finalUrl = currentUrl;
            const candidateNames: string[] = [];
            let detectedAddress = '';
            let finalBody = '';

            const initialDetails = this.extractNameAndAddressFromUrl(currentUrl);
            if (initialDetails.name) {
                candidateNames.push(initialDetails.name);
                if (initialDetails.address) detectedAddress = initialDetails.address;
            }

            // Follow redirects up to 8 hops using GET
            for (let hop = 0; hop < 8; hop++) {
                const parsed = new URL(currentUrl);
                const client = parsed.protocol === 'https:' ? https : http;

                const res = await new Promise<{ statusCode: number; headers: Record<string, any>; body: string }>((resolve) => {
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
                        r.on('end', () => resolve({ statusCode: r.statusCode || 200, headers: r.headers || {}, body }));
                        r.on('close', () => resolve({ statusCode: r.statusCode || 200, headers: r.headers || {}, body }));
                    });
                    req.on('error', () => resolve({ statusCode: 500, headers: {}, body: '' }));
                    req.on('timeout', () => { req.destroy(); resolve({ statusCode: 408, headers: {}, body: '' }); });
                });

                finalUrl = currentUrl;
                finalBody = res.body || '';

                const details = this.extractNameAndAddressFromUrl(currentUrl);
                if (details.name && !candidateNames.includes(details.name)) {
                    candidateNames.push(details.name);
                }
                if (details.address && !detectedAddress) {
                    detectedAddress = details.address;
                }

                // Check Location header for redirect (301, 302, 303, 307, 308)
                if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
                    const nextUrl = new URL(res.headers.location, currentUrl).toString();
                    const nextDetails = this.extractNameAndAddressFromUrl(nextUrl);
                    if (nextDetails.name && !candidateNames.includes(nextDetails.name)) {
                        candidateNames.push(nextDetails.name);
                    }
                    if (nextDetails.address && !detectedAddress) {
                        detectedAddress = nextDetails.address;
                    }
                    currentUrl = nextUrl;
                    continue;
                }

                break;
            }

            this.logger.log(`Final Google Maps URL: ${finalUrl}, candidates: ${JSON.stringify(candidateNames)}`);

            // Parse HTML for business title & thumbnail
            let htmlTitle = '';
            let ogImage = '';

            // 1. JSON title [null, "Place Name", [[...
            const jsonMatch = finalBody.match(/\[null,\s*"([^"\\]*(?:\\.[^"\\]*)*)",\s*\[\[(?:\d|\.)/);
            if (jsonMatch && jsonMatch[1]) {
                try {
                    const parsedTitle = JSON.parse(`"${jsonMatch[1]}"`);
                    if (!this.isInvalidBusinessName(parsedTitle)) htmlTitle = this.cleanBusinessName(parsedTitle);
                } catch (_) {
                    if (!this.isInvalidBusinessName(jsonMatch[1])) htmlTitle = this.cleanBusinessName(jsonMatch[1]);
                }
            }

            // 2. og:title meta
            if (!htmlTitle) {
                const ogTitleMatch = finalBody.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i) ||
                    finalBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i);
                if (ogTitleMatch && ogTitleMatch[1]) {
                    const cleanOg = this.cleanBusinessName(ogTitleMatch[1]);
                    if (!this.isInvalidBusinessName(cleanOg)) htmlTitle = cleanOg;
                }
            }

            // 3. <title> tag
            if (!htmlTitle) {
                const rawTitleMatch = finalBody.match(/<title[^>]*>([^<]+)<\/title>/i);
                if (rawTitleMatch && rawTitleMatch[1]) {
                    const cleanRaw = this.cleanBusinessName(rawTitleMatch[1]);
                    if (!this.isInvalidBusinessName(cleanRaw)) htmlTitle = cleanRaw;
                }
            }

            // 4. Extract og:image
            const ogImageMatch = finalBody.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i) ||
                finalBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i);
            if (ogImageMatch && ogImageMatch[1]) {
                ogImage = ogImageMatch[1].replace(/&amp;/g, '&');
            }
            if (!ogImage || !ogImage.startsWith('http')) {
                ogImage = 'https://maps.gstatic.com/tactile/pane/default_geocode-2x.png';
            }

            // Pick the best business name
            const finalBusinessName = htmlTitle || (candidateNames.length > 0 ? candidateNames[candidateNames.length - 1] : '');

            if (!finalBusinessName || this.isInvalidBusinessName(finalBusinessName)) {
                return {
                    success: false,
                    error: 'Could not detect business name from the provided Google Maps link. Please verify the link or enter the name manually.',
                    mapsUrl: finalUrl,
                };
            }

            // 5. Inferred Category & Rich Description
            let category = 'Local Business & Services';
            const lowerName = finalBusinessName.toLowerCase();
            if (lowerName.includes('cater')) category = 'Catering & Event Food Services';
            else if (lowerName.includes('restaurant') || lowerName.includes('hotel') || lowerName.includes('cafe') || lowerName.includes('dhaba') || lowerName.includes('dining') || lowerName.includes('bhojanalaya') || lowerName.includes('kitchen') || lowerName.includes('sweets') || lowerName.includes('bakery')) category = 'Restaurant & Dining';
            else if (lowerName.includes('salon') || lowerName.includes('parlour') || lowerName.includes('spa') || lowerName.includes('beauty')) category = 'Beauty, Spa & Wellness';
            else if (lowerName.includes('hospital') || lowerName.includes('clinic') || lowerName.includes('doctor') || lowerName.includes('dental') || lowerName.includes('pharma') || lowerName.includes('med')) category = 'Healthcare & Medical Clinic';
            else if (lowerName.includes('store') || lowerName.includes('shop') || lowerName.includes('mart') || lowerName.includes('supermarket') || lowerName.includes('bazaar') || lowerName.includes('jewel')) category = 'Retail Store & Shopping';
            else if (lowerName.includes('gym') || lowerName.includes('fitness') || lowerName.includes('yoga')) category = 'Fitness, Gym & Sports';
            else if (lowerName.includes('auto') || lowerName.includes('garage') || lowerName.includes('motors') || lowerName.includes('service center') || lowerName.includes('tyre')) category = 'Automotive & Repair Services';
            else if (lowerName.includes('school') || lowerName.includes('coaching') || lowerName.includes('academy') || lowerName.includes('classes') || lowerName.includes('institute') || lowerName.includes('college')) category = 'Education & Coaching Institute';

            let description = '';
            const metaDescMatch = finalBody.match(/<meta[^>]+(?:name|property)=["'](?:description|og:description)["'][^>]+content=["']([^"']+)["']/i) ||
                finalBody.match(/<meta[^>]+content=["']([^"']+)["'][^>]+(?:name|property)=["'](?:description|og:description)["']/i);
            if (metaDescMatch && metaDescMatch[1] && !metaDescMatch[1].includes('Find local businesses') && !metaDescMatch[1].includes('Google Maps')) {
                description = this.cleanBusinessName(metaDescMatch[1]);
            }

            if (!description) {
                description = detectedAddress
                    ? `${category} located at ${detectedAddress}. Verified Google Maps listing.`
                    : `${category} • Verified Google Maps business listing. Ready for authentic 5-star customer reviews & rating boost.`;
            }

            this.logger.log(`✓ Detected Business: "${finalBusinessName}" (Category: "${category}", Desc: "${description}")`);

            return {
                success: true,
                businessName: finalBusinessName,
                businessIcon: ogImage,
                description,
                category,
                address: detectedAddress,
                mapsUrl: finalUrl,
            };
        } catch (err: any) {
            this.logger.error(`Error resolving Google Maps metadata: ${err.message}`, err.stack);
            return {
                success: false,
                error: `Could not fetch Google Maps profile: ${err.message}`,
            };
        }
    }
}
