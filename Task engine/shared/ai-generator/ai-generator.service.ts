import { Injectable, Logger } from '@nestjs/common';
import { DeepSeekCommentGenerator } from './generators/deepseek-comment.generator';
import { YouTubeCommentGenerator } from './generators/youtube-comment.generator';
import { PlayStoreReviewGenerator } from './generators/playstore-review.generator';
import { GenerationOptions, IContentGenerator } from './generators/generator.interface';
import { sanitizeReviewText } from './review-sanitizer';

@Injectable()
export class AiGeneratorService {
    private readonly logger = new Logger(AiGeneratorService.name);
    private readonly generators = new Map<string, IContentGenerator>();

    constructor(
        private readonly deepSeekGen: DeepSeekCommentGenerator,
        private readonly youtubeCommentGen: YouTubeCommentGenerator,
        private readonly playStoreReviewGen: PlayStoreReviewGenerator,
    ) {
        this.generators.set('youtube_comment', this.deepSeekGen);
        this.generators.set('youtube_combo', this.deepSeekGen);
        this.generators.set('social_comment', this.deepSeekGen);
        this.generators.set('playstore_review', this.deepSeekGen);
        this.generators.set('google_play_review', this.deepSeekGen);
        this.generators.set('playstore_rating', this.playStoreReviewGen);
        this.generators.set('app_review', this.playStoreReviewGen);
        this.generators.set('template_comment', this.youtubeCommentGen);
        this.generators.set('template_review', this.playStoreReviewGen);
    }

    async generateContentBatch(
        generatorType: string,
        count: number,
        options?: GenerationOptions,
    ): Promise<string[]> {
        this.logger.log(`Generating batch of ${count} items using generator '${generatorType}' (Lang: ${options?.language || 'EN'}, Tone: ${options?.tone || 'natural'})`);

        const generator = this.generators.get(generatorType) || this.deepSeekGen;
        
        // Handle in micro-batches if count is large (e.g. 500+)
        const batchSize = 100;
        const allResults: string[] = [];

        for (let i = 0; i < count; i += batchSize) {
            const currentChunkSize = Math.min(batchSize, count - i);
            const chunk = await generator.generateBatch(currentChunkSize, options);
            allResults.push(...chunk);
        }

        return allResults
            .map((text) => sanitizeReviewText(text))
            .filter((text) => text.length > 3)
            .slice(0, count);
    }
}
