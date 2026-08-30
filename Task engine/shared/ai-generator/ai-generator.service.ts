import { Injectable, Logger } from '@nestjs/common';
import { YouTubeCommentGenerator } from './generators/youtube-comment.generator';
import { GenerationOptions, IContentGenerator } from './generators/generator.interface';

@Injectable()
export class AiGeneratorService {
    private readonly logger = new Logger(AiGeneratorService.name);
    private readonly generators = new Map<string, IContentGenerator>();

    constructor(
        private readonly youtubeCommentGen: YouTubeCommentGenerator,
    ) {
        this.generators.set('youtube_comment', this.youtubeCommentGen);
        this.generators.set('youtube_combo', this.youtubeCommentGen);
    }

    async generateContentBatch(
        generatorType: string,
        count: number,
        options?: GenerationOptions,
    ): Promise<string[]> {
        this.logger.log(`Generating batch of ${count} items using generator '${generatorType}' (Lang: ${options?.language || 'EN'}, Tone: ${options?.tone || 'natural'})`);

        const generator = this.generators.get(generatorType) || this.youtubeCommentGen;
        
        // Handle in micro-batches if count is large (e.g. 500+)
        const batchSize = 100;
        const allResults: string[] = [];

        for (let i = 0; i < count; i += batchSize) {
            const currentChunkSize = Math.min(batchSize, count - i);
            const chunk = await generator.generateBatch(currentChunkSize, options);
            allResults.push(...chunk);
        }

        return allResults.slice(0, count);
    }
}
