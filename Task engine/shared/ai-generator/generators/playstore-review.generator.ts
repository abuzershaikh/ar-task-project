import { Injectable } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';
import { sanitizeReviewText, cleanBrandName, cleanTopic } from '../review-sanitizer';

@Injectable()
export class PlayStoreReviewGenerator implements IContentGenerator {

    private readonly generalEn = [
        'Very smooth and responsive app. Does exactly what it promises without unnecessary clutter.',
        'Clean UI and great user experience. Everything works seamlessly right from the start.',
        'Super fast, lightweight and intuitive. Very happy with the overall performance.',
        'Simple, clean, and gets the job done quickly. Exactly what I was looking for.',
        'One of the best apps in this category. Works like a charm and saves me so much time.',
        'Really impressed with how fast and reliable it is. Zero lags or crashes experienced.',
        'Top notch user experience! Everything is neat, intuitive, and works as advertised.',
        'I have tried similar applications, but this one is by far the cleanest and easiest to use.',
        'Very helpful and well-designed app. Outstanding work by the development team.',
        'Works effortlessly. Very stable and dependable on every device.',
        'Terrific app! Smooth performance, no bugs or glitches encountered so far.',
        'Clean design, fast loading speeds, and very intuitive navigation throughout.',
        'Everything runs seamlessly right out of the box. Highly recommended to everyone.',
        'Great utility with top tier design. Definitely worth keeping on my daily device.',
        'Super easy to navigate and very well optimized. Kudos to the creators.',
        'Minimalist layout, lightning fast responses, and super convenient. Great job.',
        'Remarkable stability and smooth transitions. Very satisfied with how it works.',
        'Practical, convenient, and reliable. Solves the purpose perfectly.',
        'A truly polished and user-centric Android app. Makes everyday tasks effortless.',
        'One of the cleanest apps I have installed recently. Zero complaints.'
    ];

    private readonly brandEn = [
        'Using {brand} has been a great experience. Smooth navigation and very reliable.',
        '{brand} makes things so much easier and convenient. Love the simple design.',
        'Really glad I installed {brand}. Fast performance and no unnecessary hassle.',
        '{brand} runs effortlessly on my phone. Very clean interface and quick responses.',
        'Great job by the developers behind {brand}. Highly recommended application.',
        'The speed and responsiveness on {brand} are top class. Everything works without any issues.',
        '{brand} has become my go-to app for this. Super dependable and hassle-free.'
    ];

    private readonly keywordEn = [
        'Particularly like the {keyword} feature, works smoothly and reliably.',
        'The {keyword} process is super fast and straightforward.',
        'Very pleased with how {keyword} is handled. Quick and without any hassle.',
        'Everything regarding {keyword} is well thought out and polished.'
    ];

    private readonly generalHi = [
        'Bohot hi smooth chal raha hai, UI ekdum clean aur fast hai.',
        'Kamaal ka application hai, use karna bohot aasan aur convenient hai.',
        'Bohot accha user experience mila, bilkul lag nahi karta.',
        'Sabhi features bohot acche se kaam kar rahe hain. Zabardast performance.',
        'Shaandar design aur super fast speed hai. Maza aa gaya use karke.',
        'Abhi tak ka sabse best app hai is category me. Bohot helpful hai.',
        'Bohot helpful app hai, download karke maza aa gaya. Har cheez smooth hai.',
        'Daily use ke liye best app hai, kaam bohot aasan ho gaya isse.',
        'Phone me bohot halka aur fast chalta hai, koi bug ya lag dekhne ko nahi mila.',
        'Developers ne bohot accha kaam kiya hai, interface bohot friendly hai.',
        'Ekdum badhiya service hai, simple aur reliable.',
        'Kaafi time se use kar raha hu, abhi tak koi dikkat nahi aayi. Highly recommended.',
        'Har feature time par aur bina kisi pareshani ke kaam karta hai.',
        'Simple, clean aur super fast application hai. Sabhi ko zaroor try karna chahiye.',
        'Superb quality aur smooth animation. Bohot pasand aaya ye app.',
        'Bohot kaam ka app hai. Speed aur interface dono top class hain.',
        'Aasan aur seedha sadha system hai, koi faltu ads ya clutter nahi hai.',
        'Bilkul flawless chalta hai, reliable aur genuine experience mila.'
    ];

    private readonly brandHi = [
        '{brand} use karke bohot accha laga, process bohot fast aur simple hai.',
        '{brand} ka interface bohot clean aur aasan hai, koi bhi aaram se use kar sakta hai.',
        '{brand} ne kaam bohot aasan bana diya hai, bohot hi badhiya app hai.',
        'Maine pehli baar {brand} use kiya aur experience kaafi accha raha. Sabhi ko recommend karunga.',
        '{brand} application bohot acche se optimize kiya gaya hai. Zero lag aur quick response.'
    ];

    private readonly keywordHi = [
        'Khas taur par iska {keyword} feature bohot badhiya kaam kar raha hai.',
        '{keyword} ka process ekdum fast aur bina kisi dikkat ke ho gaya.',
        'Isme {keyword} use karna bohot simple aur convenient laga mujhe.'
    ];

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const brand = cleanBrandName(options?.appName);
        const keyword = cleanTopic(options?.topic, brand);
        const language = (options?.language || 'English').toLowerCase();
        const isHindi = language.includes('hindi') || language.includes('hinglish');

        const generalPool = isHindi ? [...this.generalHi] : [...this.generalEn];
        const brandPool = isHindi ? [...this.brandHi] : [...this.brandEn];
        const keywordPool = isHindi ? [...this.keywordHi] : [...this.keywordEn];

        // Shuffle arrays
        this.shuffle(generalPool);
        this.shuffle(brandPool);
        this.shuffle(keywordPool);

        const results = new Set<string>();
        let generalIdx = 0;
        let brandIdx = 0;
        let keywordIdx = 0;

        let attempts = 0;
        const maxAttempts = count * 20;

        while (results.size < count && attempts < maxAttempts) {
            attempts++;
            let reviewText = '';
            const roll = Math.random();

            if (brand && roll < 0.35 && brandPool.length > 0) {
                const template = brandPool[brandIdx % brandPool.length];
                brandIdx++;
                reviewText = template.replace('{brand}', brand);
            } else if (keyword && roll >= 0.35 && roll < 0.6 && keywordPool.length > 0) {
                const template = keywordPool[keywordIdx % keywordPool.length];
                keywordIdx++;
                reviewText = template.replace('{keyword}', keyword);
            } else {
                reviewText = generalPool[generalIdx % generalPool.length];
                generalIdx++;
            }

            const clean = sanitizeReviewText(reviewText);
            if (clean && clean.length > 10) {
                results.add(clean);
            }
        }

        // Fill remainder if needed
        const list = Array.from(results);
        while (list.length < count) {
            const fallback = generalPool[list.length % generalPool.length];
            list.push(sanitizeReviewText(fallback));
        }

        return list.slice(0, count);
    }

    private shuffle<T>(array: T[]): void {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
    }
}
