/**
 * Strips all star symbols, emojis, and rating numbers/phrases from reviews.
 * Enforces a purely natural, human-written tone.
 */
export function sanitizeReviewText(text: string): string {
    if (!text) return '';

    return text
        // Strip unicode emojis, symbols, and star characters
        .replace(/[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}⭐★🌟✨🌠🎖️🏅🏆💯🔥👍👎]/gu, '')
        // Strip star rating phrases
        .replace(/\b5\s*stars?\b/gi, '')
        .replace(/\b5\s*\/\s*5\b/gi, '')
        .replace(/\bfive\s*stars?\b/gi, '')
        .replace(/\b5-star\s*(rating)?\b/gi, '')
        .replace(/\bfull\s*5\s*stars?\b/gi, '')
        .replace(/\bsolid\s*5\s*stars?\b/gi, '')
        .replace(/\b5\s*star\b/gi, '')
        .replace(/\bworth\s*all\s*stars?\b/gi, '')
        .replace(/\bgiving\s*a?\s*full\s*rating\b/gi, '')
        // Strip leading/trailing quote characters often output by LLMs
        .replace(/^["'`\s]+|["'`\s]+$/g, '')
        // Fix spacing around punctuation
        .replace(/\s+([.,!?])/g, '$1')
        .replace(/\s{2,}/g, ' ')
        .trim();
}

/**
 * Extracts clean, single-word or short brand name from a raw app name.
 * e.g. "Cashify: Sell & Buy Old Phones" -> "Cashify"
 * e.g. "Spotify: Music and Podcasts" -> "Spotify"
 * e.g. "PhonePe UPI, Payments, Recharge" -> "PhonePe"
 */
export function cleanBrandName(rawName?: string): string {
    if (!rawName) return '';
    let name = rawName.trim();

    // Strip anything after colon, hyphen, dash, pipe, or bracket
    name = name.split(/[:\-|–—•(]/)[0].trim();

    // Strip generic suffixes
    name = name
        .replace(/\s+(app|application|mobile|official|online|android)$/i, '')
        .trim();

    // If package name like com.company.app, take the last segment
    if (name.includes('.')) {
        const parts = name.split('.');
        name = parts[parts.length - 1];
    }

    // Capitalize first letter
    if (name.length > 0) {
        name = name.charAt(0).toUpperCase() + name.slice(1);
    }

    // Never return a brand name that is longer than 25 characters (likely a sentence)
    if (name.length > 25) {
        return name.substring(0, 20).trim();
    }

    return name;
}

/**
 * Validates and cleans a topic/keyword phrase.
 * If topic is long (like a pasted description) or matches app title, it returns empty string
 * to prevent injecting entire descriptions into reviews!
 */
export function cleanTopic(topic?: string, brandName?: string): string {
    if (!topic) return '';
    const clean = topic.trim();

    // If topic is longer than 35 characters, it's a description/slogan, not a keyword
    if (clean.length > 35) return '';

    // If topic has multiple sentences, URLs, or line breaks, drop it
    if (clean.includes('.') || clean.includes('\n') || clean.includes('http')) return '';

    // If topic is identical to brand name, drop it to avoid repetition
    if (brandName && clean.toLowerCase() === brandName.toLowerCase()) return '';

    return clean;
}
