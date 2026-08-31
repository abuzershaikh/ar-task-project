import { Injectable, Logger } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';
import { YouTubeCommentGenerator } from './youtube-comment.generator';
import * as https from 'https';

@Injectable()
export class DeepSeekCommentGenerator implements IContentGenerator {
    private readonly logger = new Logger(DeepSeekCommentGenerator.name);
    private readonly apiKey = process.env.DEEPSEEK_API_KEY || '';

    constructor(
        private readonly templateFallbackGen: YouTubeCommentGenerator,
    ) { }

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const topic = options?.topic?.trim() || '';
        const language = options?.language || 'English';
        const tone = options?.tone || 'natural';
        const videoTitle = options?.videoTitle || '';

        this.logger.log(`🤖 Requesting DeepSeek AI for ${count} comments (Topic: "${topic}", Lang: ${language}, Tone: ${tone})`);

        try {
            if (!this.apiKey) {
                this.logger.warn('DEEPSEEK_API_KEY not configured, falling back to template generator');
                return this.templateFallbackGen.generateBatch(count, options);
            }

            const prompt = `Generate exactly ${count} completely distinct, authentic, natural, human-like comments for a social media / YouTube video.
- Topic / Keywords: "${topic || 'Interesting and valuable video'}"
- Language: "${language}" (e.g. if Hindi/Hinglish, write naturally in Roman script or Devanagari based on common YouTube usage)
- Tone: "${tone}" (e.g. natural, enthusiastic, professional, or questioning)
${videoTitle ? `- Video Context: "${videoTitle}"` : ''}

Rules:
1. Every comment MUST be distinct in wording, structure, length, and sentiment from all other comments.
2. Comments must sound like genuine human community members and active viewers, NOT robotic bots.
3. Return ONLY a valid JSON array of ${count} strings without any markdown code blocks, backticks, or extra explanation.
Example format:
["First comment text here", "Second unique comment text here"]`;

            const payload = JSON.stringify({
                model: 'deepseek-chat',
                messages: [
                    {
                        role: 'system',
                        content: 'You are an expert social media community member and engagement writer. You generate genuine, human-like, unique comments and reviews. Always return ONLY a raw JSON array of strings.',
                    },
                    {
                        role: 'user',
                        content: prompt,
                    },
                ],
                temperature: 0.85,
                max_tokens: Math.max(500, count * 80),
            });

            const rawContent = await this.callDeepSeekHttps(payload);
            if (!rawContent) {
                throw new Error('Empty response from DeepSeek API');
            }

            const parsedComments = this.parseComments(rawContent, count);
            if (parsedComments.length >= count) {
                this.logger.log(`✓ DeepSeek AI successfully generated ${parsedComments.length} unique comments`);
                return parsedComments.slice(0, count);
            } else if (parsedComments.length > 0) {
                this.logger.log(`DeepSeek returned partial set (${parsedComments.length}/${count}), filling remainder with template generator`);
                const remaining = count - parsedComments.length;
                const fallbackItems = await this.templateFallbackGen.generateBatch(remaining, options);
                return [...parsedComments, ...fallbackItems].slice(0, count);
            } else {
                throw new Error('Could not parse comments from DeepSeek response');
            }
        } catch (error: any) {
            this.logger.error(`DeepSeek API error: ${error.message}. Falling back to template generator.`, error.stack);
            return this.templateFallbackGen.generateBatch(count, options);
        }
    }

    private callDeepSeekHttps(payload: string): Promise<string> {
        return new Promise((resolve, reject) => {
            const options: https.RequestOptions = {
                hostname: 'api.deepseek.com',
                path: '/chat/completions',
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(payload),
                },
                timeout: 25000,
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => (data += chunk));
                res.on('end', () => {
                    try {
                        const json = JSON.parse(data);
                        if (json.error) {
                            reject(new Error(`DeepSeek API error: ${JSON.stringify(json.error)}`));
                            return;
                        }
                        const content = json.choices?.[0]?.message?.content?.trim();
                        resolve(content || '');
                    } catch (e: any) {
                        reject(new Error(`Failed to parse DeepSeek response JSON: ${e.message}`));
                    }
                });
            });

            req.on('error', (e) => reject(e));
            req.on('timeout', () => {
                req.destroy();
                reject(new Error('DeepSeek API request timed out'));
            });

            req.write(payload);
            req.end();
        });
    }

    private parseComments(content: string, expectedCount: number): string[] {
        const cleanContent = content
            .replace(/^```json\s*/i, '')
            .replace(/^```\s*/i, '')
            .replace(/\s*```$/i, '')
            .trim();

        // 1. Attempt JSON parse
        try {
            const parsed = JSON.parse(cleanContent);
            if (Array.isArray(parsed)) {
                return parsed
                    .map((item) => (typeof item === 'string' ? item.trim() : String(item).trim()))
                    .filter((c) => c.length > 5);
            }
        } catch (_) {
            // Not pure JSON, proceed to regex / line matching
        }

        // 2. Attempt line-by-line / numbered extraction
        const lines = cleanContent
            .split('\n')
            .map((line) => line.replace(/^[\d+.\-•*\]\[\s"]+/, '').replace(/[",\s]+$/, '').trim())
            .filter((line) => line.length > 8);

        return lines;
    }
}
