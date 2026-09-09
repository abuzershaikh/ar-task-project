import { Injectable } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';

@Injectable()
export class YouTubeCommentGenerator implements IContentGenerator {

    /**
     * Extracts a clean, human-readable subject and domain category from videoTitle and user prompt.
     */
    private extractSubjectAndDomain(rawTitle?: string, rawTopic?: string): { subject: string; domain: string } {
        const title = (rawTitle || '').trim();
        const topic = (rawTopic || '').trim();

        // 1. Clean video title from common YouTube clutter
        let clean = (title || topic)
            .replace(/https?:\/\/\S+/gi, '')
            .replace(/[\[\(][^\]\)]*(?:official|music|video|4k|hd|1080p|full|ep\s*\d+|part\s*\d+|season\s*\d+)[^\]\)]*[\]\)]/gi, '')
            .replace(/\s*\|\s*[^|]+$/g, '') // remove trailing "| Channel Name"
            .replace(/\s+[-–—]\s+[^–—]+$/g, '') // remove trailing " - Author"
            .replace(/#\w+/g, '') // remove hashtags
            .replace(/\b(202[0-9]|hindi|urdu|english|full\s*video|watch\s*now)\b/gi, '')
            .replace(/\s+/g, ' ')
            .trim();

        // If title was too long or contained colons, take the primary clause
        if (clean.includes(':')) {
            clean = clean.split(':')[0].trim();
        }

        // Clean common sentence ending verbs or awkward particles
        clean = clean
            .replace(/\b(ka\s*lia|k\s*lia)\b/gi, 'ke liye')
            .replace(/\s+hai$/gi, '')
            .replace(/\s+h$/gi, '')
            .trim();

        // If empty, fallback
        if (clean.length < 3) {
            clean = topic.length > 2 ? topic : 'this topic';
        }

        const lowerCombined = `${title} ${topic}`.toLowerCase();

        // 2. Domain classification
        let domain = 'general';
        if (/python|java|javascript|react|flutter|node|typescript|coding|programming|developer|api|backend|frontend|tutorial|bug|github|html|css|sql|database|software\s*eng/i.test(lowerCombined)) {
            domain = 'coding';
        } else if (/app|software|tool|bot|extension|sender|bulk|whatsapp|apk|download|automation/i.test(lowerCombined)) {
            domain = 'app';
        } else if (/biryani|recipe|cooking|cook|chicken|paneer|cake|kitchen|food|dish|tasty|taste|masala|chef|sweet|roti|breakfast|dinner|lunch/i.test(lowerCombined)) {
            domain = 'food';
        } else if (/iphone|samsung|smartphone|laptop|gadget|unboxing|review|camera|processor|battery|android|pc|macbook|display|spec|tech|gpu|cpu/i.test(lowerCombined)) {
            domain = 'tech';
        } else if (/trading|stock|share\s*market|crypto|bitcoin|nifty|banknifty|candlestick|chart|forex|option|intraday|invest|demat|broker/i.test(lowerCombined)) {
            domain = 'trading';
        } else if (/gym|workout|fat\s*loss|weight\s*loss|muscle|diet|protein|fitness|exercise|bicep|chest|transformation|belly/i.test(lowerCombined)) {
            domain = 'fitness';
        } else if (/gameplay|pubg|free\s*fire|bgmi|minecraft|gta|gaming|gamer|walkthrough|boss\s*fight|stream/i.test(lowerCombined)) {
            domain = 'gaming';
        } else if (/song|singing|cover|guitar|lyrics|beats|music|singer|vocals|acoustic|track/i.test(lowerCombined)) {
            domain = 'music';
        } else if (/car|bike|motorcycle|scooter|ev|electric|mileage|ride|vehicle|test\s*drive|engine|tata|mahindra/i.test(lowerCombined)) {
            domain = 'automotive';
        } else if (/vlog|travel|trip|tour|daily\s*vlog|explore|places|journey|mountains|hotel|flight/i.test(lowerCombined)) {
            domain = 'travel';
        } else if (/exam|study|syllabus|preparation|notes|interview|marks|chapter|cbse|upsc|jee|neet/i.test(lowerCombined)) {
            domain = 'education';
        }

        return { subject: clean, domain };
    }

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const rawTopic = (options?.topic || '').trim();
        const rawTitle = (options?.videoTitle || '').trim();
        const language = (options?.language || 'English').toLowerCase();
        const tone = (options?.tone || 'natural').toLowerCase();

        const isHindi = language.includes('hindi') || language.includes('hinglish');
        const { subject, domain } = this.extractSubjectAndDomain(rawTitle, rawTopic);

        // Intent detection from user prompt
        const lowerPrompt = `${rawTopic} ${rawTitle}`.toLowerCase();
        const isPart2 = /part\s*2|part\s*two|next\s*part|next\s*video|sequel|agla\s*part|doosra\s*part|part2/i.test(lowerPrompt);
        const isAudio = /audio|mic|voice|sound|clarity|awaz|aawaz|noise/i.test(lowerPrompt);
        const isQuestion = tone === 'questioning' || /question|doubt|kaise|query|sawal|why|how|setting/i.test(lowerPrompt);

        // Compile subject-specific comment pools
        const pool: string[] = [];

        // 1. Part 2 Intent
        if (isPart2) {
            if (isHindi) {
                pool.push(
                    `Bhai iska Part 2 kab aayega? Jaldi upload karo please!`,
                    `${subject} ka next part besabri se wait kar raha hu, bohot zabardast explanation tha.`,
                    `Bhai agla part zaroor lana, aage ka concept bhi detail me dekhna hai!`,
                    `${subject} ka Part 2 jaldi lao bhai, poora topic complete dekhna hai!`,
                    `Subscribed! Please agla part jaldi drop karna bhai, can't wait!`,
                    `Bhai Part 2 me thoda aur advance level cover karna, ye video bohot mast tha!`
                );
            } else {
                pool.push(
                    `Really hope there is a Part 2 coming out soon! Left me wanting more.`,
                    `Can you please drop Part 2 on ${subject} as soon as possible? Super excited!`,
                    `Waiting eagerly for part 2, this explanation was crystal clear.`,
                    `Bro we need Part 2 on this immediately, loved the breakdown of ${subject}!`,
                    `Please make a follow-up video covering the next steps soon!`,
                    `Subscribed just for Part 2! Please do not keep us waiting too long.`
                );
            }
        }

        // 2. Audio Intent
        if (isAudio) {
            if (isHindi) {
                pool.push(
                    `Audio quality ekdum crystal clear hai bhai, sunne me maza aa gaya!`,
                    `Aapki voice clarity aur sound setup bohot badhiya hai, har point easily samajh aaya.`,
                    `Super crisp mic quality! Audio aur video dono top tier hain bhai.`
                );
            } else {
                pool.push(
                    `The audio quality and mic clarity are top notch, super easy to follow.`,
                    `Loved the crisp sound and voiceover, made following along effortless.`,
                    `Voice clarity is 10/10 in this video, great production quality!`
                );
            }
        }

        // 3. Domain Specific comments
        if (domain === 'coding') {
            if (isHindi) {
                pool.push(
                    `${subject} ke concepts bohot hi simple aur easy tareeke se explain kiye hain aapne bhai!`,
                    `Real-world code examples aur logic explanation bohot solid tha, bohot helpful tutorial.`,
                    `Step by step flow bohot clean tha, ${subject} samajhne me koi confusion nahi raha.`,
                    `Aapka teaching style bohot practical hai bhai, seedha point to point code samjhaya!`,
                    `${subject} sikhne ke liye YouTube par sabse best video hai ye, maza aa gaya.`,
                    `Bhai GitHub repo ka link bhi description me share kar dena, practice karne ke liye.`,
                    `Beginners ke liye itne aasan tareeke se samjhaya aapne, thank you so much!`,
                    `${subject} par aur bhi advanced projects par video banate rahiye, full support!`
                );
            } else {
                pool.push(
                    `The way you broke down ${subject} with clear code examples made everything click!`,
                    `Hands down one of the most practical and concise guides on ${subject}.`,
                    `The step-by-step implementation of ${subject} was incredibly lucid and well-paced.`,
                    `Really appreciate how beginner-friendly yet technically thorough this explanation is!`,
                    `One of the cleanest tutorials on YouTube for ${subject}. Bookmarked for reference!`,
                    `Loved that you focused on best practices and real-world logic rather than just syntax.`
                );
            }
        } else if (domain === 'food') {
            if (isHindi) {
                pool.push(
                    `${subject} ki recipe bohot hi aasan aur authentic tareeke se batayi aapne!`,
                    `Masalo ka ratio aur cooking timing bohot perfect bataya, weekend pe zaroor try karunga!`,
                    `Step-by-step process dekh ke lag raha hai bohot swadisht banega, thank you recipe ke liye.`,
                    `Bohot simple aur detailed recipe hai ${subject} ki, dekh ke hi muh me paani aa gaya!`,
                    `Aapke bataye tareeke se banaya, bilkul restaurant jaisa taste aaya!`,
                    `Itne simple ingredients ke sath itni lajawab recipe, bohot badhiya video!`
                );
            } else {
                pool.push(
                    `The recipe steps and ingredient proportions for ${subject} were explained so well!`,
                    `Loved how simple and accessible you made this ${subject} recipe, definitely trying it out.`,
                    `The step-by-step cooking demonstration looks so delicious, fantastic video!`,
                    `Appreciate the clear measurement tips, makes recreating this recipe so much easier.`
                );
            }
        } else if (domain === 'tech') {
            if (isHindi) {
                pool.push(
                    `${subject} ka detailed review aur real-world testing bohot honest aur accurate tha bhai!`,
                    `Camera aur performance ka comparison bohot crystal clear bataya aapne.`,
                    `${subject} ke pros aur cons ka breakdown bohot helpful raha, decision lene me asani hogi.`,
                    `Bohot hi honest aur unbiased video banayi hai ${subject} par, keep it up bhai!`,
                    `Day-to-day battery life aur heating issue par jo bataya wo best point tha.`,
                    `Top quality video production bhai, ${subject} ki har ek detail cover ki hai.`
                );
            } else {
                pool.push(
                    `Super detailed and honest breakdown of ${subject}, helped clear all my doubts!`,
                    `Loved the practical testing and real-world performance review of ${subject}.`,
                    `One of the most unbiased and thorough reviews of ${subject} on YouTube!`,
                    `The comparison points regarding battery and real-world speed were very helpful.`
                );
            }
        } else if (domain === 'trading') {
            if (isHindi) {
                pool.push(
                    `${subject} ka market setup aur risk management bohot practical bataya aapne!`,
                    `Chart analysis aur price action ka tareeka ekdum accurate hai bhai, taking notes!`,
                    `${subject} sikhne ke liye sabse best aur disciplined video hai ye.`,
                    `Aapka chart reading aur SL lagane ka tareeka bohot safe hai, shukriya bhai!`,
                    `Intraday me aisi clarity bohot kam log dete hain, super explanation!`
                );
            } else {
                pool.push(
                    `The risk management and chart strategy explained for ${subject} are top notch!`,
                    `Super insightful breakdown of ${subject}, price action analysis was on point.`,
                    `Very disciplined approach to trading without unnecessary hype, loved it!`,
                    `Clear, objective, and super practical explanation of market structure.`
                );
            }
        } else if (domain === 'fitness') {
            if (isHindi) {
                pool.push(
                    `${subject} ke liye form aur proper technique bohot ache se samjhaya aapne bhai!`,
                    `Diet aur workout structure bohot realistic aur achievable bataya, full motivation!`,
                    `Bina kisi confusion ke scientific tareeka samjhaya aapne, bohot helpful video.`,
                    `Routine follow karna start kar diya hai, results zaroor aayenge!`
                );
            } else {
                pool.push(
                    `The exercise form and proper technique for ${subject} were demonstrated so clearly!`,
                    `Realistic, sustainable and well-structured advice for ${subject}, thanks a lot!`,
                    `Appreciate how you explained the anatomy and muscle engagement so simply.`
                );
            }
        } else {
            // General / Universal context-aware comments
            if (isHindi) {
                pool.push(
                    `${subject} ke baare me itne aasan aur saral tareeke se samjhane ke liye shukriya bhai!`,
                    `${subject} par bohot saare doubts the mere, is video ke baad sab clear ho gaya.`,
                    `Content quality aur explanation bohot top notch hai, ${subject} par aage bhi videos banate rahiye!`,
                    `Seedha point to point baat ki hai ${subject} par, zero time waste aur high value content!`,
                    `${subject} ko lekar itni detailed explanation YouTube par pehli baar dekhi, superb!`,
                    `Bohot hi informative video, har ek point bohot logic ke sath samjhaya aapne.`,
                    `Full support bhai! Channel subscribe kar diya, aise hi informative videos late rahiye!`
                );
            } else {
                pool.push(
                    `The way you explained ${subject} was exceptionally clear and easy to follow!`,
                    `This cleared up all my confusion regarding ${subject}, really appreciate the depth!`,
                    `Straight to the point with zero fluff, one of the best videos on ${subject}.`,
                    `Super informative and actionable breakdown of ${subject}, keep up the great work!`,
                    `Genuinely one of the most well-structured guides on ${subject} out there, bookmarked!`,
                    `Appreciate the effort and depth put into this presentation, highly valuable!`
                );
            }
        }

        // Add tone enhancements
        if (tone === 'questioning') {
            if (isHindi) {
                pool.push(
                    `Bhai ek doubt tha, kya ye process beginners ke liye bhi utna hi effective rahega?`,
                    `Bhai isme step 2 ko agar skip karein to koi issue hoga kya? Plz reply.`
                );
            } else {
                pool.push(
                    `Quick question: how would this apply if someone is starting with zero background?`,
                    `Would love to hear your thoughts on scaling this further over time.`
                );
            }
        }

        // Shuffle pool
        const shuffled = [...pool].sort(() => Math.random() - 0.5);
        const results = new Set<string>();
        let idx = 0;

        while (results.size < count && idx < shuffled.length * 3) {
            const item = shuffled[idx % shuffled.length];
            idx++;
            if (!results.has(item) && item.length > 10) {
                results.add(item);
            }
        }

        return Array.from(results).slice(0, count);
    }
}
