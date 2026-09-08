import { Injectable, Logger } from '@nestjs/common';
import * as https from 'https';

export interface YouTubeVideoInfo {
    success: boolean;
    videoId?: string;
    title?: string;
    thumbnail?: string;
    durationSeconds?: number;
    durationFormatted?: string;
    requiredWatchSeconds?: number;
    requiredWatchFormatted?: string;
    isCappedAt5Min?: boolean;
    error?: string;
}

@Injectable()
export class YouTubeMetadataService {
    private readonly logger = new Logger(YouTubeMetadataService.name);

    /**
     * Extract 11-character YouTube video ID from various link formats:
     * - https://www.youtube.com/watch?v=VIDEO_ID
     * - https://youtu.be/VIDEO_ID
     * - https://www.youtube.com/shorts/VIDEO_ID
     * - https://www.youtube.com/embed/VIDEO_ID
     * - https://m.youtube.com/watch?v=VIDEO_ID
     * - Bare 11-char ID
     */
    extractVideoId(input: string): string | null {
        if (!input) return null;
        const clean = input.trim();
        const regExp = /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})/i;
        const match = clean.match(regExp);
        if (match && match[1]) {
            return match[1];
        }
        if (/^[\w-]{11}$/.test(clean)) {
            return clean;
        }
        return null;
    }

    /**
     * Format seconds into human readable "Xm Ys" format
     */
    formatDuration(seconds: number): string {
        if (seconds <= 0) return '0s';
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        if (mins === 0) return `${secs}s`;
        if (secs === 0) return `${mins}m`;
        return `${mins}m ${secs}s`;
    }

    /**
     * Fetch video duration and metadata directly from YouTube public HTML.
     * Enforces the 5-Minute Cap Rule:
     * - If video duration > 300s (5 min), required watch time is 300s (5 minutes).
     * - If video duration <= 300s, required watch time is the full video duration.
     */
    async getVideoMetadata(input: string): Promise<YouTubeVideoInfo> {
        const videoId = this.extractVideoId(input);
        if (!videoId) {
            return { success: false, error: 'Invalid YouTube link or video ID' };
        }

        return new Promise<YouTubeVideoInfo>((resolve) => {
            const url = `https://www.youtube.com/watch?v=${videoId}`;
            this.logger.log(`Fetching YouTube video metadata for videoId: ${videoId}`);

            const options: https.RequestOptions = {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept-Language': 'en-US,en;q=0.9',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                },
                timeout: 8000,
            };

            const req = https.get(url, options, (res) => {
                let html = '';
                res.setEncoding('utf8');

                res.on('data', (chunk) => {
                    html += chunk;
                    // Optimistic early abort if both duration and title have been found
                    if (html.includes('"lengthSeconds":') && html.includes('og:title')) {
                        res.destroy();
                    }
                });

                res.on('end', () => {
                    resolve(this.parseHtmlMetadata(videoId, html));
                });

                res.on('close', () => {
                    resolve(this.parseHtmlMetadata(videoId, html));
                });
            });

            req.on('error', (err) => {
                this.logger.warn(`Failed to fetch YouTube page for ${videoId}: ${err.message}`);
                // Fallback gracefully with default HQ thumbnail
                resolve({
                    success: true,
                    videoId,
                    title: 'YouTube Video',
                    thumbnail: `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`,
                    durationSeconds: 300,
                    durationFormatted: '5m 0s',
                    requiredWatchSeconds: 300,
                    requiredWatchFormatted: '5m 0s',
                    isCappedAt5Min: true,
                });
            });

            req.on('timeout', () => {
                req.destroy();
                this.logger.warn(`Timeout fetching YouTube page for ${videoId}`);
                resolve({
                    success: true,
                    videoId,
                    title: 'YouTube Video',
                    thumbnail: `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`,
                    durationSeconds: 300,
                    durationFormatted: '5m 0s',
                    requiredWatchSeconds: 300,
                    requiredWatchFormatted: '5m 0s',
                    isCappedAt5Min: true,
                });
            });
        });
    }

    private parseHtmlMetadata(videoId: string, html: string): YouTubeVideoInfo {
        // 1. Duration extraction
        let durationSeconds = 0;
        const lengthMatch = html.match(/"lengthSeconds":"(\d+)"/);
        if (lengthMatch) {
            durationSeconds = parseInt(lengthMatch[1], 10);
        } else {
            const metaDuration = html.match(/itemprop="duration" content="PT(?:(\d+)M)?(?:(\d+)S)?"/);
            if (metaDuration) {
                const mins = parseInt(metaDuration[1] || '0', 10);
                const secs = parseInt(metaDuration[2] || '0', 10);
                durationSeconds = (mins * 60) + secs;
            }
        }

        // 2. Title extraction
        let title = '';
        const titleMatch = html.match(/<meta property="og:title" content="([^"]+)"/);
        if (titleMatch) {
            title = titleMatch[1].replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'");
        } else {
            const pageTitle = html.match(/<title>([^<]+)<\/title>/);
            if (pageTitle) {
                title = pageTitle[1].replace(/\s*-\s*YouTube$/, '').trim();
            }
        }
        if (!title) title = 'YouTube Video';

        // 3. Thumbnail extraction
        let thumbnail = `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;
        const thumbMatch = html.match(/<meta property="og:image" content="([^"]+)"/);
        if (thumbMatch && thumbMatch[1].startsWith('http')) {
            thumbnail = thumbMatch[1];
        }

        // 4. 5-Minute Cap Rule Logic
        // If duration > 300s (5 min), required watch time is capped at 300 seconds (5 min)
        // If duration <= 300s and > 0, full video must be watched
        // Fallback: 60s if duration could not be extracted
        let requiredWatchSeconds = durationSeconds;
        let isCappedAt5Min = false;

        if (durationSeconds > 300) {
            requiredWatchSeconds = 300;
            isCappedAt5Min = true;
        } else if (durationSeconds <= 0) {
            durationSeconds = 60;
            requiredWatchSeconds = 60;
        }

        return {
            success: true,
            videoId,
            title,
            thumbnail,
            durationSeconds,
            durationFormatted: this.formatDuration(durationSeconds),
            requiredWatchSeconds,
            requiredWatchFormatted: this.formatDuration(requiredWatchSeconds),
            isCappedAt5Min,
        };
    }
}
