import { Injectable } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';
import { sanitizeReviewText, cleanBrandName, cleanTopic } from '../review-sanitizer';

@Injectable()
export class GoogleBusinessReviewGenerator implements IContentGenerator {

    private readonly generalEn = [
        'Outstanding customer service and very welcoming atmosphere. Highly recommended!',
        'Had a wonderful experience here. The staff was extremely professional and polite.',
        'Top notch service and great attention to detail. Will definitely be visiting again.',
        'Extremely satisfied with the overall experience. Very efficient and reliable team.',
        'One of the best places in town. Prompt response, clean environment, and great support.',
        'Very impressed with the quality and friendliness. Everything exceeded my expectations.',
        'Smooth and hassle-free service from start to finish. Truly a 5-star experience.',
        'Professionalism at its best. They genuinely care about customer satisfaction.',
        'Great ambiance, polite staff, and reasonable pricing. Very glad I chose them.',
        'Quick turnaround and very helpful guidance throughout. Keep up the excellent work!',
        'Exceptional quality and timely service. I will definitely recommend them to friends and family.',
        'Very dependable and trustworthy. The whole process was completely seamless.',
        'Had a great visit today. Staff went above and beyond to make sure everything was perfect.',
        'Honest, reliable, and prompt. Best customer care I have experienced in a long time.',
        'Neat, organized, and very well managed. Highly satisfied with my experience here.',
        'Super friendly staff and quick service. Everything was handled with great care.',
        'Remarkable service quality! They resolved everything quickly without any delays.',
        'Always a pleasure dealing with such dedicated and courteous professionals.',
        'Top quality standards and authentic service. Completely satisfied with the outcome.',
        'A truly positive experience. Very clean setup, respectful team, and fast delivery.'
    ];

    private readonly brandEn = [
        'Visiting {brand} was a wonderful experience. Staff was polite and very cooperative.',
        '{brand} provides top tier service with great professionalism and attention to detail.',
        'Really glad I chose {brand}. Fast service, polite team, and zero hassle.',
        'The team at {brand} is courteous, knowledgeable, and very prompt. Highly recommended.',
        'Outstanding experience at {brand}. Everything was handled smoothly from start to finish.',
        '{brand} has become my go-to choice for this service. Dependable and trustworthy.',
        'Super satisfied with the quality of service provided by {brand}. Keep up the great work!'
    ];

    private readonly generalHi = [
        'Bohot hi acchi service aur staff ka behaviour kaafi polite aur helpful tha.',
        'Kamaal ka experience raha, har cheez time par aur bina kisi pareshani ke ho gayi.',
        'Staff bohot cooperative hai aur service quality ekdum top class hai.',
        'Shaandar service aur bohot clean environment mila. 100% satisfied!',
        'Bohot genuine aur trustworthy jagah hai. Mera experience bohot badhiya raha.',
        'Yahan ki service aur guidance dono lajawab hain. Zaroor recommend karunga sabhi ko.',
        'Kaam bohot smoothly aur jaldi ho gaya. Staff ne har cheez acche se samjhayi.',
        'Customer satisfaction par pura dhyan dete hain, bohot accha laga yahan aakar.',
        'Service fast hai aur staff ka nature bohot humble hai. Best experience mila.',
        'Har cheez well-managed aur organized thi. Bilkul 5-star service hai.',
        'Bohot badiya support mila, kisi bhi cheez me koi dikkat nahi aayi.',
        'Quality aur commitment dono number one hain. Truly exceptional experience!',
        'Pehli baar visit kiya aur overall service dekhkar kaafi khush hu.',
        'Bohot professional approach hai aur pricing bhi ekdum genuine hai.',
        'Time par delivery aur prompt support mila. Aage bhi yahi se service lunga.'
    ];

    private readonly brandHi = [
        '{brand} me service bohot acchi mili, staff kaafi helpful aur polite tha.',
        'Mera experience {brand} ke saath bohot shandar raha, sabhi kaam time par hue.',
        '{brand} ki team bohot professional hai, customer ko bohot acche se attend karte hain.',
        'Agar reliable aur fast service chahiye toh {brand} best choice hai.',
        '{brand} par pura trust kiya ja sakta hai, transparent aur smooth service mili.',
        '{brand} ki quality aur customer care dono top level hain. Highly recommended!'
    ];

    generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const brand = cleanBrandName((options as any)?.appName || (options as any)?.businessName);
        const userPrompt = cleanTopic(options?.topic, brand);
        const language = (options?.language || 'English').toLowerCase();
        const isHindi = language.includes('hindi') || language.includes('hinglish') || language.includes('roman');

        const reviews: string[] = [];
        const seen = new Set<string>();

        // 1. Build context-aware custom variations if user supplied a prompt
        const promptVariations: string[] = [];
        if (userPrompt && userPrompt.length > 3) {
            if (isHindi) {
                promptVariations.push(
                    `${userPrompt} ke maamle me inki service bohot badiya aur reliable hai.`,
                    `Khaas karke ${userPrompt} ka arrangement bohot shandar tha, maza aa gaya.`,
                    `Staff ne ${userPrompt} bohot acche se handle kiya, very satisfied.`,
                    `${userPrompt} par inka dhyan aur quality dono lajawab hain.`
                );
            } else {
                promptVariations.push(
                    `Really impressed with their ${userPrompt}. Handled with utmost care and professionalism.`,
                    `The quality regarding ${userPrompt} was top notch. Highly satisfied with the result.`,
                    `They paid special attention to ${userPrompt}, making the whole experience effortless.`,
                    `Prompt, dependable and exceptional work on ${userPrompt}. Truly appreciated!`
                );
            }
        }

        // Shuffle arrays for organic variety
        const customPool = [...promptVariations].sort(() => Math.random() - 0.5);
        const generalPool = isHindi ? [...this.generalHi].sort(() => Math.random() - 0.5) : [...this.generalEn].sort(() => Math.random() - 0.5);
        const brandPool = isHindi ? [...this.brandHi].sort(() => Math.random() - 0.5) : [...this.brandEn].sort(() => Math.random() - 0.5);

        let customIdx = 0;
        let genIdx = 0;
        let brandIdx = 0;

        for (let i = 0; i < count; i++) {
            let candidate = '';

            // Every 3rd review can feature brand name if available
            if (brand && i % 3 === 0 && brandPool.length > 0) {
                candidate = brandPool[brandIdx % brandPool.length].replace(/{brand}/g, brand);
                brandIdx++;
            } else if (customPool.length > 0 && i % 2 === 1 && customIdx < customPool.length * 2) {
                candidate = customPool[customIdx % customPool.length];
                customIdx++;
            } else {
                candidate = generalPool[genIdx % generalPool.length];
                genIdx++;
            }

            // Fallback deduplication with slight punctuation / wording touches if count > pool
            if (seen.has(candidate)) {
                const prefixes = isHindi
                    ? ['Overall ', 'Sach me, ', 'Personal experience se bolu toh, ', 'Bina kisi doubt ke, ']
                    : ['Overall, ', 'Truly, ', 'From personal experience, ', 'Without doubt, '];
                const prefix = prefixes[i % prefixes.length];
                candidate = `${prefix}${candidate.charAt(0).toLowerCase()}${candidate.slice(1)}`;
            }

            candidate = sanitizeReviewText(candidate);
            seen.add(candidate);
            reviews.push(candidate);
        }

        return Promise.resolve(reviews);
    }
}
