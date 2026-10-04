import { Injectable, Logger } from '@nestjs/common';
import * as https from 'https';
import * as http from 'http';
import { URL } from 'url';
import { resolveShortUrl } from '../common/utils/task-identity.util';

export interface GoogleBusinessMetadata {
    success: boolean;
    businessName?: string;
    businessIcon?: string;
    mapsUrl?: string;
    address?: string;
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
            .replace(/\s*,\s*India$/i, '')
            .trim();

        // If there's an address in parentheses or after a dash, keep the main brand
        cleaned = cleaned.replace(/\s*\([^)]*\)$/, '').trim();
        return cleaned;
    }

    /**
     * Fetch Google Maps / Google Business listing details
     */
    async getBusinessMetadata(inputUrl: string): Promise<GoogleBusinessMetadata> {
        if (!inputUrl || typeof inputUrl !== 'string') {
            return { success: false, error: 'Google Maps URL is required' };
        }

        const cleanInput = inputUrl.trim();
        this.logger.log(`Fetching Google Maps metadata for: ${cleanInput}`);

        try {
            // 1. Resolve short URLs (maps.app.goo.gl, goo.gl/maps, etc.) to full URL
            const resolvedUrl = await resolveShortUrl(cleanInput);
            this.logger.log(`Resolved Google Maps URL: ${resolvedUrl}`);

            // 2. Extract potential place name directly from resolved URL
            let extractedName = '';
            const placeMatch = resolvedUrl.match(/\/maps\/place\/([^\/@?]+)/i);
            if (placeMatch && placeMatch[1]) {
                extractedName = this.cleanBusinessName(placeMatch[1]);
            } else {
                const searchMatch = resolvedUrl.match(/\/maps\/search\/([^\/@?]+)/i);
                if (searchMatch && searchMatch[1]) {
                    extractedName = this.cleanBusinessName(searchMatch[1]);
                } else {
                    const qParam = new URL(resolvedUrl).searchParams.get('q') || new URL(resolvedUrl).searchParams.get('query');
                    if (qParam) {
                        extractedName = this.cleanBusinessName(qParam);
                    }
                }
            }

            // 3. Fetch HTML content to retrieve official Title and Map/Place Image
            const htmlMetadata = await this.fetchHtmlMetadata(resolvedUrl);

            const finalName = (htmlMetadata.title && htmlMetadata.title.length > 1 && htmlMetadata.title !== 'Google Maps')
                ? this.cleanBusinessName(htmlMetadata.title)
                : extractedName;

            const finalIcon = htmlMetadata.icon || 'https://maps.gstatic.com/tactile/pane/default_geocode-2x.png';

            if (!finalName) {
                return {
                    success: false,
                    error: 'Could not detect business name from the provided Google Maps link. Please verify the link or enter the name manually.',
                    mapsUrl: resolvedUrl,
                };
            }

            return {
                success: true,
                businessName: finalName,
                businessIcon: finalIcon,
                mapsUrl: resolvedUrl,
            };
        } catch (err: any) {
            this.logger.error(`Error resolving Google Maps metadata: ${err.message}`, err.stack);
            return {
                success: false,
                error: `Could not fetch Google Maps profile: ${err.message}`,
            };
        }
    }

    private async fetchHtmlMetadata(targetUrl: string): Promise<{ title?: string; icon?: string }> {
        return new Promise((resolve) => {
            try {
                const parsed = new URL(targetUrl);
                const client = parsed.protocol === 'http:' ? http : https;

                const req = client.get(targetUrl, {
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                        'Accept-Language': 'en-US,en;q=0.9',
                        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    },
                    timeout: 6000,
                }, (res) => {
                    let body = '';
                    res.on('data', (chunk) => {
                        body += chunk;
                        if (body.length > 300000) req.destroy(); // Cap response
                    });

                    res.on('end', () => {
                        let title = '';
                        let icon = '';

                        // 1. Check title from embedded JSON: [null, "Place Name", [[...
                        const jsonMatch = body.match(/\[null,\s*"([^"\\]*(?:\\.[^"\\]*)*)",\s*\[\[(?:\d|\.)/);
                        if (jsonMatch && jsonMatch[1]) {
                            try {
                                title = JSON.parse(`"${jsonMatch[1]}"`);
                            } catch (_) {
                                title = jsonMatch[1];
                            }
                        }

                        // 2. If not found in JSON, check <meta property="og:title"> or <title>
                        if (!title || title === 'Google Maps') {
                            const metaTitleMatch = body.match(/<meta\s+property=["']og:title["']\s+content=["'](.*?)["']/i) ||
                                                   body.match(/<title>(.*?)<\/title>/i);
                            if (metaTitleMatch && metaTitleMatch[1]) {
                                title = metaTitleMatch[1];
                            }
                        }

                        // 3. Extract Image / Thumbnail
                        const iconMatch = body.match(/<meta\s+property=["']og:image["']\s+content=["'](.*?)["']/i);
                        if (iconMatch && iconMatch[1]) {
                            icon = iconMatch[1].replace(/&amp;/g, '&');
                        }

                        resolve({ title: title.trim(), icon });
                    });

                    res.on('close', () => resolve({}));
                });

                req.on('error', () => resolve({}));
                req.on('timeout', () => {
                    req.destroy();
                    resolve({});
                });
            } catch (_) {
                resolve({});
            }
        });
    }
}
