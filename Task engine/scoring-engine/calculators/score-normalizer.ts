import { Injectable } from '@nestjs/common';

/**
 * Scores ko normalize karta hai (0-100 range me)
 */
@Injectable()
export class ScoreNormalizer {
    normalize(value: number, min: number = 0, max: number = 100): number {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    normalizeToPercentile(scores: number[]): Map<number, number> {
        const sorted = [...scores].sort((a, b) => a - b);
        const percentiles = new Map<number, number>();

        scores.forEach(score => {
            const rank = sorted.indexOf(score);
            const percentile = (rank / sorted.length) * 100;
            percentiles.set(score, percentile);
        });

        return percentiles;
    }
}
