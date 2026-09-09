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
        'Straight to the point with zero fluff',
        'Bookmarking this for future reference',
        'Hands down one of the most useful videos',
        'Keep up the great work',
        'Practical, concise and very actionable',
        'High value content delivered simply'
    ];

    private readonly closersEn = [
        'Keep making more videos like this!',
        'Subscribed and waiting for the next upload!',
        'Looking forward to your upcoming videos!',
        'Definitely sharing this with friends.',
        'Much love and respect for this channel.',
        'Deserves way more views and recognition!',
        'Great work, keep it going!',
        'Subscribed! Highly recommended.',
        'Keep dropping these gems!',
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
        'Zabardast video, keep shining!',
        'Shaandar presentation, shukriya!'
    ];

    private readonly part2En = [
        'Really hope there is a Part 2 coming out soon! Left me wanting more.',
        'Can you please drop Part 2 as soon as possible? Super excited for what is next!',
        'Waiting eagerly for part 2, this explanation was crystal clear.',
        'Bro we need Part 2 on this immediately, loved the breakdown!',
        'Please make a follow-up video covering the next steps soon!',
        'Subscribed just for Part 2! Please do not keep us waiting too long.',
        'Eagerly anticipating the next part, fantastic delivery!'
    ];

    private readonly part2Hi = [
        'Bhai iska Part 2 kab aayega? Jaldi upload karo please!',
        'Part 2 ka besabri se intezar rahega, bohot zabardast explanation tha.',
        'Bhai next part zaroor lana, aage ka concept bhi detail me dekhna hai.',
        'Part 2 jaldi lao bhai, poora topic explore karna hai!',
        'Channel subscribe kar diya hai, agle part ka wait hai bhai!',
        'Bhai agla part kab drop kar rahe ho? Intezar rahega!'
    ];

    private readonly audioEn = [
        'The audio quality and mic clarity are top notch, super easy to listen to.',
        'Loved the clear sound quality and voiceover, made following along effortless.',
        'Voice clarity is 10/10 in this video, great production quality!',
        'Super crisp audio! Really appreciate creators who care about clear sound.',
        'The clear voiceover and background sound were balanced perfectly.'
    ];

    private readonly audioHi = [
        'Bhai audio quality ekdum crystal clear hai, sunne me maza aa gaya.',
        'Aapki voice clarity aur sound setup bohot badhiya hai bhai.',
        'Ekdum saaf aawaz hai, har ek point clearly samajh aaya bina kisi noise ke.',
        'Mic quality aur explanation dono top tier hain bhai!'
    ];

    private readonly tradingEn = [
        'Solid risk management strategy explained here, definitely taking notes.',
        'The way you analyzed the market setup in this video is pure gold.',
        'Best trading breakdown I have watched this month, super practical insights.',
        'Clear price action analysis without confusing fluff, loved it!',
        'Very disciplined approach to trading, thank you for sharing.'
    ];

    private readonly tradingHi = [
        'Trading strategy ekdum solid hai bhai, risk management bohot sahi bataya.',
        'Chart reading ka tareeka bohot badhiya sikhaya aapne, shukriya!',
        'Aapka market analysis hamesha accurate hota hai bhai, keep it up!',
        'Bohot kaam ka setup bataya bhai, intraday ke liye best guide hai.'
    ];

    private readonly tutorialEn = [
        'Finally someone who explains this concept straight to the point without wasting time.',
        'The breakdown at each step was so clean and easy to follow.',
        'This cleared up so much confusion for me, thanks for sharing!',
        'One of the best tutorials on this topic on YouTube, bookmarked!',
        'Hands down the most practical guide I have watched all week.'
    ];

    private readonly tutorialHi = [
        'Aapka samjhane ka tareeka sabse best hai bhai, ek baar me clear ho gaya.',
        'Point to point baat ki hai bina time waste kiye, bohot helpful raha.',
        'Itne aasan tareeke se samjhaya aapne, shukriya bhai!',
        'Bohot informative aur valuable tutorial, poora doubt clear ho gaya.'
    ];

    private readonly questionsEn = [
        'Quick question: does this approach still work with the latest update?',
        'One doubt regarding the step shown in the middle, what setting was that?',
        'Curious about your setup, what tools do you recommend for beginners?',
        'Can you share more details on how to scale this over time?'
    ];

    private readonly questionsHi = [
        'Bhai ek chota sa doubt tha, kya ye naye update me bhi chalega?',
        'Bhai aapne jo tool use kiya hai uska naam kya hai?',
        'Kya beginners bhi is tareeke ko easily follow kar sakte hain?'
    ];

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const topic = (options?.topic || '').toLowerCase().trim();
        const language = (options?.language || 'English').toLowerCase();
        const tone = (options?.tone || 'natural').toLowerCase();

        const isHindi = language.includes('hindi') || language.includes('hinglish');
        const results = new Set<string>();
        let attempts = 0;
        const maxAttempts = count * 25;

        const isPart2 = /part\s*2|part\s*two|next\s*part|next\s*video|sequel|agla\s*part|doosra\s*part|part2/i.test(topic);
        const isAudio = /audio|mic|voice|sound|clarity|awaz|aawaz|noise/i.test(topic);
        const isTrading = /trading|stock|market|crypto|forex|chart|candle|indicator|profit|nifty|banknifty/i.test(topic);
        const isTutorial = /explain|tutorial|guide|sikha|samjh|concept|sikhao|trick|step/i.test(topic);
        const isQuestion = tone === 'questioning' || /question|doubt|kaise|query|sawal|why|how|setting/i.test(topic);

        // Assemble targeted pool based on detected user prompt intent
        let targetedPool: string[] = [];
        if (isPart2) {
            targetedPool.push(...(isHindi ? this.part2Hi : this.part2En));
        }
        if (isAudio) {
            targetedPool.push(...(isHindi ? this.audioHi : this.audioEn));
        }
        if (isTrading) {
            targetedPool.push(...(isHindi ? this.tradingHi : this.tradingEn));
        }
        if (isTutorial) {
            targetedPool.push(...(isHindi ? this.tutorialHi : this.tutorialEn));
        }
        if (isQuestion) {
            targetedPool.push(...(isHindi ? this.questionsHi : this.questionsEn));
        }

        const openers = isHindi ? this.openersHi : this.openersEn;
        const closers = isHindi ? this.closersHi : this.closersEn;

        // Shuffle arrays
        const shuffledTargeted = [...targetedPool].sort(() => Math.random() - 0.5);
        let targetedIdx = 0;

        while (results.size < count && attempts < maxAttempts) {
            attempts++;
            let comment = '';

            // If user specified an intent that matched a targeted pool, prioritize it
            if (shuffledTargeted.length > 0 && Math.random() < 0.65) {
                comment = shuffledTargeted[targetedIdx % shuffledTargeted.length];
                targetedIdx++;
            } else {
                const opener = openers[Math.floor(Math.random() * openers.length)];
                const closer = closers[Math.floor(Math.random() * closers.length)];
                comment = Math.random() > 0.4 ? `${opener}! ${closer}` : `${opener}. ${closer}`;
            }

            // Adjust tone nuances naturally
            if (tone === 'enthusiastic' && !comment.includes('!') && !comment.includes('?')) {
                comment += isHindi ? ' Full support bhai!' : ' Really loved this!';
            }

            if (!results.has(comment) && comment.length >= 10) {
                results.add(comment);
            }
        }

        // Fill remainder if needed
        const list = Array.from(results);
        let fillIdx = 0;
        while (list.length < count) {
            const opener = openers[fillIdx % openers.length];
            const closer = closers[(fillIdx * 2) % closers.length];
            const fallback = `${opener}! ${closer}`;
            list.push(fallback);
            fillIdx++;
        }

        return list.slice(0, count);
    }
}
