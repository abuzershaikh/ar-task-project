import {
    compareCommentSimilarity,
    findDuplicateCommentMatches,
} from '../ai-generator/comment-duplicate-detector';
import { AiGeneratorService } from '../ai-generator/ai-generator.service';

describe('advanced comment duplicate detection', () => {
    it('detects 100% matches despite case and punctuation changes', () => {
        const result = compareCommentSimilarity(
            'This video was very helpful, thank you!',
            'this VIDEO was very helpful thank you',
        );

        expect(result.exactMatch).toBe(true);
        expect(result.similarity).toBe(1);
    });

    it('detects comments with 80% of normalized words in common', () => {
        const comments = [
            'one two three four five six seven eight nine ten',
            'one two three four five six seven eight eleven twelve',
            'different wording and perspective for this particular video comment',
        ];

        const duplicates = findDuplicateCommentMatches(comments);

        expect(duplicates).toHaveLength(1);
        expect(duplicates[0].duplicateIndex).toBe(1);
        expect(duplicates[0].matchedIndex).toBe(0);
        expect(duplicates[0].similarity.similarity).toBe(0.8);
    });

    it('leaves comments below the 80% threshold untouched', () => {
        const duplicates = findDuplicateCommentMatches([
            'one two three four five six seven eight nine ten',
            'one two three four five six seven new words different ending',
        ]);

        expect(duplicates).toHaveLength(0);
    });

    it('regenerates only duplicate slots and preserves accepted comments', async () => {
        const generator = {
            generateBatch: jest.fn(async () => ['Completely fresh perspective with original phrasing and a distinct reaction today']),
        };
        const service = new AiGeneratorService(generator as any, {} as any, {} as any, {} as any);
        const first = 'one two three four five six seven eight nine ten';
        const duplicate = 'one two three four five six seven eight eleven twelve';
        const unique = 'I enjoyed the clear examples and the practical explanation throughout this video';

        const result = await service.ensureUniqueComments(
            [first, duplicate, unique],
            3,
            'youtube_comment',
            { language: 'English', tone: 'natural' },
        );

        expect(generator.generateBatch).toHaveBeenCalledTimes(1);
        expect(generator.generateBatch).toHaveBeenCalledWith(1, expect.objectContaining({
            regenerationAttempt: 1,
            avoidComments: expect.arrayContaining([first, unique]),
        }));
        expect(result[0]).toBe(first);
        expect(result[1]).toContain('Completely fresh perspective');
        expect(result[2]).toBe(unique);
        expect(findDuplicateCommentMatches(result)).toHaveLength(0);
    });

    it('regenerates exactly 10 duplicate comments from a 50-comment YouTube batch', async () => {
        const originalUnique = Array.from(
            { length: 40 },
            (_, index) => `aurora${index} beacon${index} cedar${index} drift${index} ember${index}`,
        );
        const duplicateTail = originalUnique.slice(0, 10).map((comment) => `${comment.toUpperCase()}!!!`);
        const generator = {
            generateBatch: jest.fn(async (count: number) => Array.from(
                { length: count },
                (_, index) => `fable${index} glacier${index} harbor${index} island${index} juniper${index}`,
            )),
        };
        const service = new AiGeneratorService(generator as any, {} as any, {} as any, {} as any);

        const result = await service.ensureUniqueComments(
            [...originalUnique, ...duplicateTail],
            50,
            'youtube_comment',
            { language: 'English', tone: 'natural' },
        );

        expect(generator.generateBatch).toHaveBeenCalledTimes(1);
        expect(generator.generateBatch).toHaveBeenCalledWith(10, expect.objectContaining({
            regenerationAttempt: 1,
        }));
        expect(result.slice(0, 40)).toEqual(originalUnique);
        expect(result.slice(40)).toHaveLength(10);
        expect(findDuplicateCommentMatches(result)).toHaveLength(0);
    });
});
