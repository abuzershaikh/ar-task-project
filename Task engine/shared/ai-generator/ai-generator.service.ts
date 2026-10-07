import { Injectable, Logger } from '@nestjs/common';
import { DeepSeekCommentGenerator } from './generators/deepseek-comment.generator';
import { YouTubeCommentGenerator } from './generators/youtube-comment.generator';
import { PlayStoreReviewGenerator } from './generators/playstore-review.generator';
import { GoogleBusinessReviewGenerator } from './generators/google-business-review.generator';
import { GenerationOptions, IContentGenerator } from './generators/generator.interface';
import { sanitizeReviewText } from './review-sanitizer';
import { findDuplicateCommentMatches } from './comment-duplicate-detector';

@Injectable()
export class AiGeneratorService {
    private readonly logger = new Logger(AiGeneratorService.name);
    private readonly generators = new Map<string, IContentGenerator>();
    private static readonly maxDuplicateRegenerationAttempts = 4;

    constructor(
        private readonly deepSeekGen: DeepSeekCommentGenerator,
        private readonly youtubeCommentGen: YouTubeCommentGenerator,
        private readonly playStoreReviewGen: PlayStoreReviewGenerator,
        private readonly googleBusinessReviewGen: GoogleBusinessReviewGenerator,
    ) {
        this.generators.set('youtube_comment', this.deepSeekGen);
        this.generators.set('youtube_combo', this.deepSeekGen);
        this.generators.set('instagram_comment', this.deepSeekGen);
        this.generators.set('instagram_combo', this.deepSeekGen);
        this.generators.set('social_comment', this.deepSeekGen);
        this.generators.set('playstore_review', this.deepSeekGen);
        this.generators.set('google_play_review', this.deepSeekGen);
        this.generators.set('playstore_rating', this.deepSeekGen);
        this.generators.set('app_review', this.deepSeekGen);
        this.generators.set('google_business_review', this.deepSeekGen);
        this.generators.set('google_business_rating', this.deepSeekGen);
        this.generators.set('google_maps_review', this.deepSeekGen);
        this.generators.set('google_maps_rating', this.deepSeekGen);
        this.generators.set('gmb_review', this.deepSeekGen);
        this.generators.set('template_comment', this.deepSeekGen);
        this.generators.set('template_review', this.deepSeekGen);
        this.generators.set('template_google_review', this.deepSeekGen);
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

    /**
     * Keeps accepted comments in place and regenerates only duplicate or empty
     * slots. It never pads a campaign by reusing a previous comment.
     */
    async ensureUniqueComments(
        candidates: string[],
        targetCount: number,
        generatorType: string,
        options?: GenerationOptions,
    ): Promise<string[]> {
        const requiredCount = Math.max(0, Math.floor(Number(targetCount) || 0));
        const comments = candidates
            .slice(0, requiredCount)
            .map((comment) => sanitizeReviewText(String(comment || '')).trim());

        while (comments.length < requiredCount) {
            comments.push('');
        }

        for (let attempt = 0; attempt <= AiGeneratorService.maxDuplicateRegenerationAttempts; attempt += 1) {
            const duplicates = findDuplicateCommentMatches(comments);
            if (duplicates.length === 0) {
                return comments;
            }

            if (attempt === AiGeneratorService.maxDuplicateRegenerationAttempts) {
                throw new Error(
                    `AI could not create ${duplicates.length} sufficiently distinct comments after ${AiGeneratorService.maxDuplicateRegenerationAttempts} regeneration attempts`,
                );
            }

            const duplicateIndexes = duplicates.map((item) => item.duplicateIndex);
            const duplicateIndexSet = new Set(duplicateIndexes);
            const acceptedComments = comments.filter((comment, index) => !duplicateIndexSet.has(index) && comment.length > 0);
            this.logger.warn(
                `Detected ${duplicateIndexes.length} duplicate/empty comments at ${Math.round(Math.min(...duplicates.map((item) => item.similarity.similarity)) * 100)}%-100% similarity; regenerating only those slots (attempt ${attempt + 1}).`,
            );

            const replacements = await this.generateContentBatch(generatorType, duplicateIndexes.length, {
                ...options,
                uniqueness: true,
                avoidComments: acceptedComments.slice(-40),
                regenerationAttempt: attempt + 1,
            });

            duplicateIndexes.forEach((commentIndex, replacementIndex) => {
                comments[commentIndex] = sanitizeReviewText(String(replacements[replacementIndex] || '')).trim();
            });
        }

        return comments;
    }
}
