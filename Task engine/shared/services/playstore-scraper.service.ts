import { Injectable, Logger } from '@nestjs/common';
import * as https from 'https';

export interface PlayStoreAppInfo {
    success: boolean;
    packageId?: string;
    appName?: string;
    appIcon?: string;
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
        let clean = input.trim();

        if (clean.includes('id=')) {
            const match = clean.match(/[?&]id=([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)/i) ||
                          clean.match(/id=([a-zA-Z0-9_.]+)/i);
            if (match) {
                return match[1].replace(/\.+$/, '').split('&')[0];
            }
        }

        if (clean.startsWith('market://details?id=')) {
            return clean.replace('market://details?id=', '').split('&')[0].replace(/\.+$/, '');
        }

        // Bare package ID like com.whatsapp or com.blinkit.storeob
        const bareMatch = clean.match(/^([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)$/);
        if (bareMatch) {
            return bareMatch[1];
        }

        const urlMatch = clean.match(/([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)/);
        return urlMatch ? urlMatch[1].replace(/\.+$/, '') : null;
    }

    /**
     * Fetch app icon and suggested title from Google Play Store.
     * Note: Description extraction has been completely removed as reviews
     * are guided solely by user prompt and app name.
     */
    async getAppMetadata(input: string): Promise<PlayStoreAppInfo> {
        const packageId = this.extractPackageId(input);
        if (!packageId) {
            return { success: false, error: 'Invalid Google Play Store link or package ID' };
        }

        return new Promise<PlayStoreAppInfo>((resolve) => {
            const url = `https://play.google.com/store/apps/details?id=${packageId}&hl=en&gl=US`;
            this.logger.log(`Fetching Play Store app icon and basic info for: ${packageId}`);

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
                            // 1. App Title (suggested clean brand name)
                            const titleMatch = data.match(/<meta\s+property=["']og:title["']\s+content=["'](.*?)["']/i) ||
                                               data.match(/<title>(.*?)<\/title>/i);
                            let title = titleMatch ? titleMatch[1] : '';
                            title = title
                                .replace(/\s*-\s*Apps on Google Play.*/i, '')
                                .replace(/\s*-\s*Google Play.*/i, '')
                                .split(/[:\-|–—]/)[0] // Take only brand name
                                .replace(/&amp;/g, '&')
                                .replace(/&#39;/g, "'")
                                .replace(/&quot;/g, '"')
                                .replace(/&lt;/g, '<')
                                .replace(/&gt;/g, '>')
                                .trim();

                            // 2. High-res App Icon
                            const iconMatch = data.match(/<meta\s+property=["']og:image["']\s+content=["'](.*?)["']/i) ||
                                              data.match(/<img[^>]+src=["'](https:\/\/play-lh\.googleusercontent\.com\/[^"']+)["'][^>]*alt=["']Icon image["']/i);
                            let iconUrl = iconMatch ? iconMatch[1] : '';

                            resolve({
                                success: true,
                                packageId,
                                appName: title || packageId,
                                appIcon: iconUrl,
                                playStoreUrl: `https://play.google.com/store/apps/details?id=${packageId}`,
                            });
                        } catch (err: any) {
                            this.logger.error(`Error parsing Play Store HTML for ${packageId}: ${err.message}`);
                            resolve({
                                success: true,
                                packageId,
                                appName: packageId,
                                appIcon: '',
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
