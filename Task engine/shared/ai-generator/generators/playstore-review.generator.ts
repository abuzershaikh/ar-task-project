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

    // Targeted intent-based reviews (English)
    private readonly paymentEn = [
        'Instant and reliable payment processing, haven\'t faced a single deduction glitch.',
        'Transactions are super quick and secure, very transparent billing.',
        'Wallet and payment workflow is seamless, money reflects instantly.',
        'Very safe and fast checkout experience. Great payment security.'
    ];

    private readonly deliveryEn = [
        'Doorstep pickup and fast handling is incredible, highly punctual team.',
        'Delivery was swift and handled with care, great speed of service.',
        'Order tracking and quick fulfillment exceeded my expectations.',
        'Super fast execution, got everything sorted well ahead of time.'
    ];

    private readonly uiEn = [
        'The user interface is sleek and clutter-free, very intuitive to navigate.',
        'Minimalist layout and clean fonts, makes using the app a delight.',
        'Everything is neatly organized, finding what you need takes two taps.',
        'Modern aesthetics and fluid page transitions, truly top tier design.'
    ];

    private readonly supportEn = [
        'Customer support was very prompt and resolved my query within minutes.',
        'Help desk is super responsive and polite, genuinely care about users.',
        'Quick resolution from the support team, very satisfied with their service.',
        'Great after-service assistance, dependable help whenever needed.'
    ];

    private readonly lightweightEn = [
        'Super lightweight on phone storage and zero battery drain experienced.',
        'Runs buttery smooth even on low RAM devices, exceptionally well optimized.',
        'Zero lags, zero freezes, and app opens in a split second.',
        'Extremely stable performance with no unexpected crashes or battery hogging.'
    ];

    // Targeted intent-based reviews (Hindi)
    private readonly paymentHi = [
        'Payment process ekdum instant aur safe hai, wallet me turant reflect hota hai.',
        'Bina kisi transaction error ke payments smooth ho jati hain, bohot reliable hai.',
        'Transactions super fast hain aur koi hidden charges nahi hain, genuine service.'
    ];

    private readonly deliveryHi = [
        'Doorstep pickup aur service timing bohot fast aur punctual hai.',
        'Bohot jaldi delivery mil gayi, staff bhi bohot polite aur helpful tha.',
        'Tracking system aur fast execution bohot accha laga mujhe.'
    ];

    private readonly uiHi = [
        'UI bohot clean aur modern hai, koi bhi aaram se bina confuse hue chala sakta hai.',
        'Sabhi options seedhe aur aasan hain, navigation ekdum smooth hai.',
        'Bina kisi clutter ke sleek design banaya hai, daily use ke liye best hai.'
    ];

    private readonly supportHi = [
        'Customer support ne turant meri problem solve kar di, bohot acchi team hai.',
        'Help center ka response time kaafi fast hai, bohot polite tareeke se guide kiya.',
        'Support team genuinely helpful hai, query instant resolve ho gayi.'
    ];

    private readonly lightweightHi = [
        'Phone me bilkul bhi space nahi leta aur battery bhi waste nahi hoti.',
        'Bilkul smooth chalta hai bina kisi lag ya hang ke, lightweight app hai.',
        'Speed bohot fast hai aur application bina kisi issue ke open ho jata hai.'
    ];

    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const brand = cleanBrandName(options?.appName);
        const rawPrompt = (options?.topic || '').toLowerCase().trim();
        const language = (options?.language || 'English').toLowerCase();
        const isHindi = language.includes('hindi') || language.includes('hinglish');

        const isPayment = /pay|upi|money|transaction|wallet|paisa|cash|billing|checkout/i.test(rawPrompt);
        const isDelivery = /deliver|pickup|speed|fast|doorstep|service|courier|timing|punctual/i.test(rawPrompt);
        const isUi = /ui|design|interface|clean|navigation|simple|layout|modern/i.test(rawPrompt);
        const isSupport = /support|help|service|care|team|contact|query|assist/i.test(rawPrompt);
        const isLightweight = /lag|slow|battery|light|size|smooth|performance|bug|hang|ram/i.test(rawPrompt);

        let targetedPool: string[] = [];
        if (isPayment) targetedPool.push(...(isHindi ? this.paymentHi : this.paymentEn));
        if (isDelivery) targetedPool.push(...(isHindi ? this.deliveryHi : this.deliveryEn));
        if (isUi) targetedPool.push(...(isHindi ? this.uiHi : this.uiEn));
        if (isSupport) targetedPool.push(...(isHindi ? this.supportHi : this.supportEn));
        if (isLightweight) targetedPool.push(...(isHindi ? this.lightweightHi : this.lightweightEn));

        const generalPool = isHindi ? [...this.generalHi] : [...this.generalEn];
        const brandPool = isHindi ? [...this.brandHi] : [...this.brandEn];

        this.shuffle(generalPool);
        this.shuffle(brandPool);
        this.shuffle(targetedPool);

        const results = new Set<string>();
        let generalIdx = 0;
        let brandIdx = 0;
        let targetedIdx = 0;

        let attempts = 0;
        const maxAttempts = count * 25;

        while (results.size < count && attempts < maxAttempts) {
            attempts++;
            let reviewText = '';
            const roll = Math.random();

            if (targetedPool.length > 0 && roll < 0.6) {
                reviewText = targetedPool[targetedIdx % targetedPool.length];
                targetedIdx++;
                // Optionally prefix brand name if available
                if (brand && Math.random() < 0.4) {
                    reviewText = isHindi ? `${brand} me ` + reviewText.charAt(0).toLowerCase() + reviewText.slice(1) : reviewText;
                }
            } else if (brand && roll < 0.85 && brandPool.length > 0) {
                const template = brandPool[brandIdx % brandPool.length];
                brandIdx++;
                reviewText = template.replace('{brand}', brand);
            } else {
                reviewText = generalPool[generalIdx % generalPool.length];
                generalIdx++;
            }

            const clean = sanitizeReviewText(reviewText);
            if (clean && clean.length > 10 && !results.has(clean)) {
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
