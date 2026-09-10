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
     * Fetch video duration and metadata directly.
     * Uses YouTube Innertube Player API as primary (bypasses datacenter bot-checks),
     * and oEmbed + HTML parsing as fallback.
     * Enforces the 5-Minute Cap Rule:
     * - If video duration > 300s (5 min), required watch time is 300s (5 minutes).
     * - If video duration <= 300s, required watch time is the full video duration.
     */
    async getVideoMetadata(input: string): Promise<YouTubeVideoInfo> {
        const videoId = this.extractVideoId(input);
        if (!videoId) {
            return { success: false, error: 'Invalid YouTube link or video ID' };
        }

        this.logger.log(`Fetching YouTube video metadata for videoId: ${videoId}`);

        // 1. Primary: YouTube Innertube API (ANDROID_TESTSUITE) - fast & reliably returns lengthSeconds
        let innertubeData = await this.fetchInnertube(videoId, 'ANDROID_TESTSUITE', '1.9');

        // 2. Secondary Innertube fallback if primary did not return duration
        if (!innertubeData || !innertubeData.durationSeconds) {
            innertubeData = await this.fetchInnertube(videoId, 'TVHTML5_SIMPLY_EMBEDDED_PLAYER', '2.0');
        }

        // 3. Complement / fallback with oEmbed for title, author, and thumbnail
        let title = innertubeData?.title;
        let thumbnail = innertubeData?.thumbnail || `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;

        if (!title || !thumbnail || thumbnail.includes('hqdefault')) {
            const oembed = await this.fetchOembed(videoId);
            if (oembed) {
                if (!title || title === 'YouTube Video') title = oembed.title;
                if (oembed.thumbnail) thumbnail = oembed.thumbnail;
            }
        }

        // 4. If duration is still missing, attempt web page scrape as fallback
        let durationSeconds = innertubeData?.durationSeconds || 0;
        if (durationSeconds <= 0) {
            durationSeconds = await this.scrapeHtmlDuration(videoId);
        }

        if (!title) title = 'YouTube Video';

        // 5. 5-Minute Cap Rule Logic
        let requiredWatchSeconds = durationSeconds;
        let isCappedAt5Min = false;

        if (durationSeconds > 300) {
            requiredWatchSeconds = 300;
            isCappedAt5Min = true;
        } else if (durationSeconds <= 0) {
            durationSeconds = 120; // fallback to 2 minutes (120s) if duration undetectable
            requiredWatchSeconds = 120;
        }

        this.logger.log(`Metadata for ${videoId}: duration=${durationSeconds}s, requiredWatch=${requiredWatchSeconds}s, capped=${isCappedAt5Min}, title="${title}"`);

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

    private async fetchInnertube(videoId: string, clientName: string, clientVersion: string): Promise<{
        title?: string;
        author?: string;
        durationSeconds?: number;
        thumbnail?: string;
    } | null> {
        return new Promise((resolve) => {
            const postData = JSON.stringify({
                context: {
                    client: {
                        clientName,
                        clientVersion,
                        hl: 'en',
                        gl: 'US'
                    }
                },
                videoId
            });

            const req = https.request({
                hostname: 'www.youtube.com',
                port: 443,
                path: '/youtubei/v1/player?prettyPrint=false',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData),
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                },
                timeout: 5000
            }, (res) => {
                let body = '';
                res.on('data', chunk => body += chunk);
                res.on('end', () => {
                    try {
                        const json = JSON.parse(body);
                        const details = json.videoDetails;
                        if (details && details.lengthSeconds) {
                            const secs = parseInt(details.lengthSeconds, 10);
                            if (secs > 0) {
                                const thumbs = details.thumbnail?.thumbnails;
                                const thumb = (thumbs && thumbs.length > 0)
                                    ? thumbs[thumbs.length - 1].url
                                    : `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;

                                resolve({
                                    title: details.title,
                                    author: details.author,
                                    durationSeconds: secs,
                                    thumbnail: thumb
                                });
                                return;
                            }
                        }
                    } catch (_) {}
                    resolve(null);
                });
            });

            req.on('error', () => resolve(null));
            req.on('timeout', () => {
                req.destroy();
                resolve(null);
            });
            req.write(postData);
            req.end();
        });
    }

    private async fetchOembed(videoId: string): Promise<{
        title?: string;
        author?: string;
        thumbnail?: string;
    } | null> {
        return new Promise((resolve) => {
            const url = `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`;
            https.get(url, { timeout: 4000 }, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try {
                        const json = JSON.parse(data);
                        if (json.title) {
                            resolve({
                                title: json.title,
                                author: json.author_name,
                                thumbnail: json.thumbnail_url || `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`
                            });
                            return;
                        }
                    } catch (_) {}
                    resolve(null);
                });
            }).on('error', () => resolve(null))
              .on('timeout', () => resolve(null));
        });
    }

    private async scrapeHtmlDuration(videoId: string): Promise<number> {
        return new Promise((resolve) => {
            const url = `https://www.youtube.com/watch?v=${videoId}`;
            const options: https.RequestOptions = {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept-Language': 'en-US,en;q=0.9',
                },
                timeout: 5000,
            };

            https.get(url, options, (res) => {
                let html = '';
                res.on('data', chunk => {
                    html += chunk;
                    if (html.includes('"lengthSeconds":')) res.destroy();
                });
                res.on('end', () => {
                    const lengthMatch = html.match(/"lengthSeconds":"(\d+)"/);
                    if (lengthMatch) {
                        return resolve(parseInt(lengthMatch[1], 10));
                    }
                    const metaDuration = html.match(/itemprop="duration" content="PT(?:(\d+)M)?(?:(\d+)S)?"/);
                    if (metaDuration) {
                        const mins = parseInt(metaDuration[1] || '0', 10);
                        const secs = parseInt(metaDuration[2] || '0', 10);
                        return resolve((mins * 60) + secs);
                    }
                    resolve(0);
                });
                res.on('close', () => resolve(0));
            }).on('error', () => resolve(0))
              .on('timeout', () => resolve(0));
        });
    }
}
