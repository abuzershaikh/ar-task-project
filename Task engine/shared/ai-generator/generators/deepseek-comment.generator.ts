import { Injectable, Logger } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';
import { YouTubeCommentGenerator } from './youtube-comment.generator';
import { PlayStoreReviewGenerator } from './playstore-review.generator';
import { GoogleBusinessReviewGenerator } from './google-business-review.generator';
import { sanitizeReviewText, cleanBrandName, cleanTopic } from '../review-sanitizer';
import * as https from 'https';

@Injectable()
export class DeepSeekCommentGenerator implements IContentGenerator {
    private readonly logger = new Logger(DeepSeekCommentGenerator.name);

    constructor(
        private readonly templateFallbackGen: YouTubeCommentGenerator,
        private readonly playStoreFallbackGen: PlayStoreReviewGenerator,
        private readonly googleBusinessFallbackGen: GoogleBusinessReviewGenerator,
    ) { }

    private getApiKey(options?: GenerationOptions): string {
        return (options?.apiKey || process.env.DEEPSEEK_API_KEY || '').trim();
    }

    private normalizeModel(rawModel: string): string {
        const m = rawModel.trim().toLowerCase();
        if (m === 'deepseek-v3' || m === 'v3' || m === 'deepseek-v3.0' || m === 'latest') {
            return 'deepseek-chat';
        }
        if (m === 'deepseek-r1' || m === 'r1' || m === 'deepseek-r1.0') {
            return 'deepseek-reasoner';
        }
        return rawModel.trim();
    }

    private getModel(options?: GenerationOptions): string {
        // DeepSeek's official chat model identifier: 'deepseek-chat' (DeepSeek-V3 flagship 671B)
        // DeepSeek's reasoning model identifier: 'deepseek-reasoner' (DeepSeek-R1)
        const requested = options?.model || process.env.DEEPSEEK_MODEL || 'deepseek-chat';
        return this.normalizeModel(requested);
    }

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const brand = cleanBrandName(options?.appName);
        const userPrompt = cleanTopic(options?.topic, brand);
        const language = options?.language || 'English';
        const tone = options?.tone || 'natural';
        const videoTitle = options?.videoTitle || '';

        const isGoogleBusiness = (options as any)?.isGoogleBusiness || (options as any)?.generatorType?.includes('google_business') || (options as any)?.generatorType?.includes('google_maps') || (options as any)?.generatorType?.includes('gmb');
        const isAppReview = !isGoogleBusiness && ((options as any)?.isAppReview || (options as any)?.generatorType?.includes('review') || (options as any)?.generatorType?.includes('play'));
        const contextType = isGoogleBusiness
            ? 'Google Business / Google Maps (Natural Customer Review)'
            : (isAppReview ? 'Google Play Store Android App (Natural Human Review)' : 'social media / YouTube video');
        const fallbackGen = isGoogleBusiness
            ? this.googleBusinessFallbackGen
            : (isAppReview ? this.playStoreFallbackGen : this.templateFallbackGen);

        const apiKey = this.getApiKey(options);
        const model = this.getModel(options);
        const isReasoner = model.toLowerCase().includes('reasoner') || model.toLowerCase().includes('r1');

        this.logger.log(`🤖 Requesting AI for ${count} items (Type: ${contextType}, Model: ${model} [${isReasoner ? 'Reasoning/R1' : 'Chat/V3'}], Title: "${videoTitle}", Brand: "${brand}", Prompt: "${userPrompt}", Lang: ${language}, Tone: ${tone})`);

        try {
            if (!apiKey) {
                this.logger.warn(`DEEPSEEK_API_KEY is not configured in .env or request. Using smart contextual generator. Model configured: ${model}`);
                return fallbackGen.generateBatch(count, options);
            }

            const prompt = isGoogleBusiness
                ? `You are an authentic local customer writing a genuine 5-star review for a business on Google Maps / Google Business.
Generate exactly ${count} completely distinct, authentic, natural, human-written 5-star Google reviews.

Business Details:
${brand ? `- Target Business Name: "${brand}"` : '- Target: Local Business / Store / Service'}
${userPrompt ? `- Customer Experience / Review Focus: "${userPrompt}"\n  CRITICAL DIRECTIVE: Follow the buyer's instructions above to shape what the reviews praise or highlight (e.g., great service, polite staff, fast delivery, quality products, clean ambiance, prompt communication). DO NOT repeat or quote the buyer's prompt verbatim! Express the requested points naturally as if you visited or used their service personally.` : '- Review Focus: Outstanding customer service, polite staff, high quality, smooth experience, and great overall satisfaction'}
- Language: "${language}" (write naturally as real everyday customers write on Google Maps; if Hindi or Hinglish, write in natural conversational Roman Hindi)
- Tone: "${tone}" (natural, polite, authentic customer sharing genuine positive feedback)

CRITICAL RULES:
1. ABSOLUTELY NO star symbols (like ⭐, ★, 🌟, ✨), NO emojis, and NO rating numbers.
2. Tone MUST be 100% human, casual, and authentic. Write like real customers who had a great real-world experience.
3. Every review MUST be completely distinct in vocabulary, sentence structure, length, and perspective.
4. DO NOT quote or copy-paste the prompt text verbatim!
5. Return ONLY a valid JSON array of ${count} strings without any markdown code blocks, backticks, or extra explanation.
Example format:
["First authentic customer review", "Second authentic customer review"]`
                : (isAppReview
                    ? `You are an authentic everyday user writing a genuine review for an Android application on Google Play Store.
Generate exactly ${count} completely distinct, authentic, natural, human-written 5-star reviews.

App Information:
${brand ? `- Target App Name: "${brand}"` : '- Target App: Android mobile application'}
${userPrompt ? `- Buyer's Prompt / Instructions: "${userPrompt}"\n  CRITICAL DIRECTIVE: Follow the buyer's instructions above to shape what the reviews praise or focus on. DO NOT repeat or quote the buyer's prompt verbatim! Express the requested points naturally as if you experienced them personally.` : '- Review Focus: Everyday user experience, smooth performance, intuitive interface, reliable stability'}
- Language: "${language}" (write naturally as real everyday users write in this language; if Hindi or Hinglish, write in natural conversational Roman Hindi as commonly seen on Play Store reviews)
- Tone: "${tone}" (natural, casual, honest everyday user)

CRITICAL RULES:
1. ABSOLUTELY NO star symbols (like ⭐, ★, 🌟, ✨), NO emojis, and NO rating numbers.
2. Tone MUST be 100% human, casual, and authentic. Write like real people sharing their real experience.
3. Every review MUST be completely distinct in vocabulary, sentence structure, and perspective.
4. Return ONLY a valid JSON array of ${count} strings without any markdown code blocks, backticks, or extra explanation.
Example format:
["First authentic review", "Second authentic review"]`
                    : `You are an authentic community member and active viewer writing comments on a YouTube video.
Generate exactly ${count} completely distinct, authentic, natural, human-written comments tailored directly to this video.

Video Details:
${videoTitle ? `- Video Title: "${videoTitle}"` : '- Context: Engaging, high-value YouTube video'}
${userPrompt ? `- Buyer's Custom Prompt / Topic Instructions: "${userPrompt}"\n  CRITICAL DIRECTIVE: The text above provides custom instructions for what the comments should say or request. Fulfill these instructions creatively and naturally across the generated comments (e.g., if asking for Part 2, request Part 2; if praising audio or specific tips, highlight that). DO NOT quote or copy-paste the prompt text verbatim! Express the intent with diverse, natural human phrasing.` : '- Topic: High-value video tutorial / presentation'}
- Language: "${language}" (write naturally as real active YouTube viewers write in this language; if Hindi or Hinglish, write in natural conversational Roman Hindi or Devanagari as commonly used by viewers)
- Tone: "${tone}" (e.g. natural, enthusiastic, insightful, questioning)

CRITICAL RULES:
1. Comments MUST be directly relevant to the video title and topic.
2. Every comment MUST be distinct in wording, structure, length, and sentiment from all other comments.
3. Comments must sound like genuine human community members and active viewers, NOT robotic bots.
4. ABSOLUTELY NO star symbols or rating symbols.
5. DO NOT copy-paste the prompt text into the comments. Follow its instructions naturally!
6. Return ONLY a valid JSON array of ${count} strings without any markdown code blocks, backticks, or extra explanation.
Example format:
["First unique natural comment here", "Second unique natural comment here"]`);

            const payloadObj: any = {
                model: model,
                messages: [
                    {
                        role: 'system',
                        content: 'You are an authentic everyday human user and community member writing genuine, natural, conversational comments and reviews. You tailor comments specifically to the video title and topic provided. You carefully follow custom user instructions. You NEVER use star symbols (⭐, ★), emojis, or text star ratings. You NEVER repeat or echo the user prompt literally—you always express the intended points with varied, authentic human words. Return ONLY a raw JSON array of strings.',
                    },
                    {
                        role: 'user',
                        content: prompt,
                    },
                ],
                max_tokens: isReasoner ? Math.max(2500, count * 350) : Math.max(600, count * 100),
            };

            // Note: Temperature parameter is not supported by deepseek-reasoner (DeepSeek-R1) and triggers a 400 error
            if (!isReasoner) {
                payloadObj.temperature = 0.88;
            }

            const payload = JSON.stringify(payloadObj);
            const timeoutMs = isReasoner ? 45000 : 25000;
            const rawContent = await this.callDeepSeekHttps(payload, apiKey, timeoutMs);
            if (!rawContent) {
                throw new Error('Empty response from DeepSeek API');
            }

            const parsedComments = this.parseComments(rawContent, count);
            if (parsedComments.length >= count) {
                this.logger.log(`✓ DeepSeek AI (${model}) successfully generated ${parsedComments.length} unique comments`);
                return parsedComments.slice(0, count);
            } else if (parsedComments.length > 0) {
                this.logger.log(`DeepSeek returned partial set (${parsedComments.length}/${count}), filling remainder with contextual generator`);
                const remaining = count - parsedComments.length;
                const fallbackItems = await fallbackGen.generateBatch(remaining, options);
                return [...parsedComments, ...fallbackItems].slice(0, count);
            } else {
                throw new Error('Could not parse comments from DeepSeek response');
            }
        } catch (error: any) {
            this.logger.error(`DeepSeek API error: ${error.message}. Using contextual generator.`, error.stack);
            return fallbackGen.generateBatch(count, options);
        }
    }

    private callDeepSeekHttps(payload: string, apiKey: string, timeoutMs: number = 25000): Promise<string> {
        return new Promise((resolve, reject) => {
            const options: https.RequestOptions = {
                hostname: 'api.deepseek.com',
                path: '/chat/completions',
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(payload),
                },
                timeout: timeoutMs,
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
                        const choice = json.choices?.[0]?.message;
                        const content = choice?.content?.trim() || choice?.reasoning_content?.trim();
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
                    .map((item) => sanitizeReviewText(typeof item === 'string' ? item : String(item)))
                    .filter((c) => c.length > 5);
            }
        } catch (_) {
            // Not pure JSON, proceed to regex / line matching
        }

        // 2. Attempt line-by-line / numbered extraction
        const lines = cleanContent
            .split('\n')
            .map((line) => sanitizeReviewText(line.replace(/^[\d+.\-•*\]\[\s"]+/, '').replace(/[",\s]+$/, '')))
            .filter((line) => line.length > 8);

        return lines;
    }
}
