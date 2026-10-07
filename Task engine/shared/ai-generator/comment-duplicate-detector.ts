export const COMMENT_DUPLICATE_SIMILARITY_THRESHOLD = 0.80;

export interface CommentSimilarity {
    exactMatch: boolean;
    wordOverlap: number;
    sequenceOverlap: number;
    similarity: number;
}

export interface DuplicateCommentMatch {
    duplicateIndex: number;
    matchedIndex: number;
    similarity: CommentSimilarity;
}

/**
 * Normalizes wording before comparison, so casing, punctuation, emoji, and
 * repeated whitespace cannot hide an otherwise duplicate comment.
 */
export function tokenizeComment(text: string): string[] {
    return String(text || '')
        .normalize('NFKD')
        .toLocaleLowerCase()
        .replace(/\p{M}/gu, '')
        .match(/[\p{L}\p{N}]+/gu) || [];
}

export function normalizedComment(text: string): string {
    return tokenizeComment(text).join(' ');
}

function multisetWordOverlap(left: string[], right: string[]): number {
    const denominator = Math.max(left.length, right.length);
    if (denominator === 0) return 0;

    const remaining = new Map<string, number>();
    for (const word of right) {
        remaining.set(word, (remaining.get(word) || 0) + 1);
    }

    let sharedWords = 0;
    for (const word of left) {
        const available = remaining.get(word) || 0;
        if (available > 0) {
            sharedWords += 1;
            remaining.set(word, available - 1);
        }
    }
    return sharedWords / denominator;
}

function longestCommonSubsequenceRatio(left: string[], right: string[]): number {
    const denominator = Math.max(left.length, right.length);
    if (denominator === 0) return 0;

    // Comments are short; this word-level LCS catches near copies even when a
    // few words were inserted, removed, or substituted.
    let previous = new Uint16Array(right.length + 1);
    for (const leftWord of left) {
        const current = new Uint16Array(right.length + 1);
        for (let j = 1; j <= right.length; j += 1) {
            current[j] = leftWord === right[j - 1]
                ? previous[j - 1] + 1
                : Math.max(previous[j], current[j - 1]);
        }
        previous = current;
    }
    return previous[right.length] / denominator;
}

/**
 * Reports both exact duplicates and comments sharing at least 80% of their
 * normalized words. Reordered copies are caught by word overlap; near copies
 * retaining the same phrase order are caught by LCS sequence overlap.
 */
export function compareCommentSimilarity(leftText: string, rightText: string): CommentSimilarity {
    const leftNormalized = normalizedComment(leftText);
    const rightNormalized = normalizedComment(rightText);
    const exactMatch = leftNormalized.length > 0 && leftNormalized === rightNormalized;
    if (exactMatch) {
        return { exactMatch: true, wordOverlap: 1, sequenceOverlap: 1, similarity: 1 };
    }

    const leftWords = leftNormalized ? leftNormalized.split(' ') : [];
    const rightWords = rightNormalized ? rightNormalized.split(' ') : [];
    const wordOverlap = multisetWordOverlap(leftWords, rightWords);
    const sequenceOverlap = longestCommonSubsequenceRatio(leftWords, rightWords);
    return {
        exactMatch: false,
        wordOverlap,
        sequenceOverlap,
        similarity: Math.max(wordOverlap, sequenceOverlap),
    };
}

/**
 * Marks only the later copy as a duplicate, preserving the first valid comment
 * and allowing callers to regenerate exactly the affected slots.
 */
export function findDuplicateCommentMatches(
    comments: string[],
    threshold = COMMENT_DUPLICATE_SIMILARITY_THRESHOLD,
): DuplicateCommentMatch[] {
    const acceptedIndexes: number[] = [];
    const duplicates: DuplicateCommentMatch[] = [];

    for (let index = 0; index < comments.length; index += 1) {
        const normalized = normalizedComment(comments[index]);
        if (!normalized) {
            duplicates.push({
                duplicateIndex: index,
                matchedIndex: -1,
                similarity: { exactMatch: false, wordOverlap: 1, sequenceOverlap: 1, similarity: 1 },
            });
            continue;
        }

        let bestMatch: DuplicateCommentMatch | null = null;
        for (const acceptedIndex of acceptedIndexes) {
            const similarity = compareCommentSimilarity(comments[index], comments[acceptedIndex]);
            if (similarity.exactMatch || similarity.similarity >= threshold) {
                if (!bestMatch || similarity.similarity > bestMatch.similarity.similarity) {
                    bestMatch = { duplicateIndex: index, matchedIndex: acceptedIndex, similarity };
                }
            }
        }

        if (bestMatch) {
            duplicates.push(bestMatch);
        } else {
            acceptedIndexes.push(index);
        }
    }

    return duplicates;
}
