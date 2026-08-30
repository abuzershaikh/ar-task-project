import { Injectable } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';

@Injectable()
export class YouTubeCommentGenerator implements IContentGenerator {

    private readonly openersEn = [
        'Really enjoyed this video',
        'Great explanation and very clear',
        'This is super helpful',
        'Awesome content as always',
        'Thanks for sharing this tutorial',
        'Such an insightful video',
        'Loved the pacing and structure',
        'Very well presented and informative',
        'The breakdown at each step was fantastic',
        'This cleared up so much confusion for me',
        'Incredible quality and depth',
        'One of the best explanations on this topic',
        'Brilliant guide',
        'Really appreciate the effort put into this video',
        'Solid points covered throughout',
        'Extremely well made and easy to follow',
        'This gave me a lot of clarity',
        'Top notch content right here',
        'Straight to the point with zero fluff',
        'Bookmarking this for future reference',
        'Hands down one of the most useful videos',
        'Keep up the great work',
        'Loved every minute of this',
        'Practical, concise and very actionable',
        'Very well researched and articulated',
        'The details you highlighted made all the difference',
        'Super clear and to the point',
        'Really good breakdown of the whole process',
        'This helped me a ton today',
        'High value content delivered simply'
    ];

    private readonly topicFollowUpsEn = [
        'especially regarding {topic}',
        'particularly the points on {topic}',
        'the practical insights about {topic} were spot on',
        'learned a lot about {topic}',
        'the way you explained {topic} made it effortless to understand',
        'the step-by-step guidance on {topic} was super clear',
        'glad you touched upon {topic}',
        'the practical approach to {topic} is genuinely appreciated',
        'really liked the real-world perspective on {topic}',
        'the key takeaway on {topic} was awesome'
    ];

    private readonly closersEn = [
        'Keep making more videos like this!',
        'Subscribed and waiting for the next upload!',
        'Looking forward to your upcoming tutorials!',
        'Definitely sharing this with friends.',
        'Much love and respect for this channel.',
        'Deserves way more views and recognition!',
        'Great work, keep it going!',
        'Can you make a follow up video soon?',
        'Subscribed! Highly recommended.',
        'Keep dropping these gems! 🔥',
        'Subbed and notifications turned on!',
        'Thanks a lot, keep inspiring us!'
    ];

    private readonly openersHi = [
        'Bohot hi badhiya aur useful video',
        'Ekdum clear explanation bhai',
        'Bohot achhe se samjhaya aapne',
        'Ye video dekh kar bohot clarity mili',
        'Kamaal ka content hai',
        'Shaandar video, bohot helpful raha',
        'Bhai bohot mehnat dikh rahi hai video me',
        'Point to point baat ki hai bina time waste kiye',
        'Top class tutorial hai ye',
        'Aapka samjhane ka tareeka bohot natural hai',
        'Ekdum simplified tareeke se bataya',
        'Bohot informative aur valuable guide'
    ];

    private readonly closersHi = [
        'Aage bhi aise helpful videos banate rahiye!',
        'Channel subscribe kar diya, next video ka intezar hai!',
        'Full support bhai, keep it up!',
        'Video like and subscribe dono kar diya!',
        'Aapki channel bohot aage jayegi!',
        'Zabardast video, keep shining! 👍',
        'Shaandar presentation, shukriya!'
    ];

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const topic = options?.topic?.trim() || '';
        const language = (options?.language || 'English').toLowerCase();
        const tone = (options?.tone || 'natural').toLowerCase();

        const isHindi = language.includes('hindi') || language.includes('hinglish');
        const results = new Set<string>();
        let attempts = 0;
        const maxAttempts = count * 20;

        const openers = isHindi ? this.openersHi : this.openersEn;
        const closers = isHindi ? this.closersHi : this.closersEn;

        while (results.size < count && attempts < maxAttempts) {
            attempts++;
            const opener = openers[Math.floor(Math.random() * openers.length)];
            const closer = closers[Math.floor(Math.random() * closers.length)];

            let comment = '';
            const roll = Math.random();

            if (topic && roll > 0.4) {
                const topicPhrase = isHindi
                    ? `khas taur par ${topic} ke baare me detail bohot achhi thi.`
                    : this.topicFollowUpsEn[Math.floor(Math.random() * this.topicFollowUpsEn.length)].replace('{topic}', topic) + '.';
                comment = `${opener}, ${topicPhrase} ${closer}`;
            } else if (roll > 0.2) {
                comment = `${opener}! ${closer}`;
            } else {
                comment = `${opener}.`;
            }

            // Adjust tone nuances
            if (tone === 'enthusiastic' && !comment.includes('!')) {
                comment += ' 🔥💯';
            } else if (tone === 'questioning' && roll > 0.6) {
                comment += isHindi
                    ? ' Is topic par ek aur detailed part 2 bana sakte ho kya?'
                    : ' Could you cover an advanced part 2 on this soon?';
            }

            // Uniqueness check
            if (!results.has(comment) && comment.length >= 10) {
                results.add(comment);
            }
        }

        // If count not yet fully filled due to large batch, generate indexed variations
        let fallbackIndex = 1;
        while (results.size < count) {
            const opener = openers[fallbackIndex % openers.length];
            const closer = closers[(fallbackIndex * 3) % closers.length];
            const uniqueComment = `${opener}! (#${fallbackIndex}) ${closer}`;
            results.add(uniqueComment);
            fallbackIndex++;
        }

        return Array.from(results).slice(0, count);
    }
}
