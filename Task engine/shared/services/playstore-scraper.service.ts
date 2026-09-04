import { Injectable, Logger } from '@nestjs/common';
import * as https from 'https';

export interface PlayStoreAppInfo {
    success: boolean;
    packageId?: string;
    appName?: string;
    appIcon?: string;
    shortDescription?: string;
    description?: string;
    playStoreUrl?: string;
    error?: string;
}

@Injectable()
export class PlayStoreScraperService {
    private readonly logger = new Logger(PlayStoreScraperService.name);

    /**
     * Extract package ID from full Play Store URL, market URI, or bare package string
     */
    extractPackageId(input: string): string | null {
        if (!input) return null;
        const trimmed = input.trim();

        if (trimmed.includes('id=')) {
            const match = trimmed.match(/id=([a-zA-Z0-9_.]+)/);
            if (match) return match[1];
        }

        if (trimmed.startsWith('market://details?id=')) {
            return trimmed.replace('market://details?id=', '').split('&')[0];
        }

        if (/^[a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+$/.test(trimmed)) {
            return trimmed;
        }

        const urlMatch = trimmed.match(/([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)/);
        return urlMatch ? urlMatch[1] : trimmed;
    }

    /**
     * Fetch app metadata (icon, title, description) directly from Google Play Store web page
     */
    async getAppMetadata(input: string): Promise<PlayStoreAppInfo> {
        const packageId = this.extractPackageId(input);
        if (!packageId) {
            return { success: false, error: 'Invalid Google Play Store link or package ID' };
        }

        return new Promise<PlayStoreAppInfo>((resolve) => {
            const url = `https://play.google.com/store/apps/details?id=${packageId}&hl=en&gl=US`;
            this.logger.log(`Fetching Play Store app metadata for: ${packageId}`);

            const req = https.get(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                    'Accept-Language': 'en-US,en;q=0.9',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                },
                timeout: 10000,
            }, (res) => {
                let data = '';
                res.on('data', (chunk) => (data += chunk));
                res.on('end', () => {
                    if (res.statusCode && res.statusCode >= 200 && res.statusCode < 400) {
                        try {
                            // 1. App Title
                            const titleMatch = data.match(/<meta\s+property=["']og:title["']\s+content=["'](.*?)["']/i) ||
                                               data.match(/<title>(.*?)<\/title>/i);
                            let title = titleMatch ? titleMatch[1] : '';
                            title = title.replace(/\s*-\s*Apps on Google Play.*/i, '').replace(/\s*-\s*Google Play.*/i, '').trim();

                            // 2. High-res App Icon
                            const iconMatch = data.match(/<meta\s+property=["']og:image["']\s+content=["'](.*?)["']/i) ||
                                              data.match(/<img[^>]+src=["'](https:\/\/play-lh\.googleusercontent\.com\/[^"']+)["'][^>]*alt=["']Icon image["']/i);
                            let iconUrl = iconMatch ? iconMatch[1] : '';

                            // 3. Descriptions
                            const fullBlock = data.match(/data-g-id=["']description["'][^>]*>([\s\S]*?)<\/div>/i) ||
                                              data.match(/itemprop=["']description["'][^>]*>([\s\S]*?)<\/div>/i);
                            const metaDescMatch = data.match(/<meta[^>]+content=["']([^"']*)["'][^>]+(?:name|property)=["'](?:og:)?description["']/i) ||
                                                  data.match(/<meta[^>]+(?:name|property)=["'](?:og:)?description["'][^>]+content=["']([^"']*)["']/i);

                            const rawDesc = (fullBlock && fullBlock[1]) ? fullBlock[1] : (metaDescMatch ? metaDescMatch[1] : '');
                            const shortDesc = metaDescMatch ? metaDescMatch[1].replace(/&amp;/g, '&').replace(/&#39;/g, "'").replace(/&quot;/g, '"').trim() : '';
                            const cleanDesc = rawDesc
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
                                appName: title || packageId,
                                appIcon: iconUrl,
                                shortDescription: shortDesc || (cleanDesc.length > 200 ? cleanDesc.substring(0, 197) + '...' : cleanDesc),
                                description: cleanDesc,
                                playStoreUrl: `https://play.google.com/store/apps/details?id=${packageId}`,
                            });
                        } catch (err: any) {
                            this.logger.error(`Error parsing Play Store HTML for ${packageId}: ${err.message}`);
                            resolve({
                                success: true,
                                packageId,
                                appName: packageId,
                                appIcon: '',
                                shortDescription: '',
                                description: '',
                                playStoreUrl: `https://play.google.com/store/apps/details?id=${packageId}`,
                            });
                        }
                    } else {
                        this.logger.warn(`Play Store returned HTTP ${res.statusCode} for package ${packageId}`);
                        resolve({
                            success: false,
                            error: `Google Play Store responded with status ${res.statusCode}. Check package ID or link.`,
                        });
                    }
                });
            });

            req.on('error', (err) => {
                this.logger.error(`Play Store HTTP request error: ${err.message}`);
                resolve({ success: false, error: err.message });
            });

            req.on('timeout', () => {
                req.destroy();
                this.logger.warn(`Play Store request timed out for: ${packageId}`);
                resolve({ success: false, error: 'Request to Google Play Store timed out.' });
            });
        });
    }
}
