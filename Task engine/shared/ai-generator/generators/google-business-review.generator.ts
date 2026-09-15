import { Injectable } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';
import { sanitizeReviewText, cleanBrandName, cleanTopic } from '../review-sanitizer';

type BusinessCategory = 'it_tech' | 'healthcare' | 'restaurant_food' | 'automotive' | 'retail_shopping' | 'education' | 'general';

@Injectable()
export class GoogleBusinessReviewGenerator implements IContentGenerator {

    private countWords(text: string): number {
        return text.trim().split(/\s+/).filter(w => w.length > 0).length;
    }

    private detectCategory(brand: string, prompt: string): BusinessCategory {
        const combined = `${brand} ${prompt}`.toLowerCase();
        if (/infotech|tech|software|web|app|digital|coding|developer|\bit\b|system|solutions|design|cyber|computer|seo|marketing|hosting/.test(combined)) {
            return 'it_tech';
        }
        if (/clinic|hospital|doctor|dental|dentist|teeth|health|pharma|medical|eye|skin|derma|ortho|care|physio|pathology|diagnostic/.test(combined)) {
            return 'healthcare';
        }
        if (/cafe|coffee|restaurant|food|dining|kitchen|hotel|pizza|burger|bakery|sweets|dhaba|biryani|bar|tea|tiffin|snack/.test(combined)) {
            return 'restaurant_food';
        }
        if (/auto|motor|car|bike|garage|tyre|wheel|repair|service center|workshop|mechanic|vehicle|spare/.test(combined)) {
            return 'automotive';
        }
        if (/shop|store|mart|market|boutique|clothes|cloth|jewel|optics|optical|electronics|appliances|hardware|furniture/.test(combined)) {
            return 'retail_shopping';
        }
        if (/institute|academy|classes|coaching|school|college|training|education|tutor|study|university|tuition/.test(combined)) {
            return 'education';
        }
        return 'general';
    }

    // ── Human Reviews Pool: Category-Specific Sentences ────────────────────────

    // 1. IT & Technology (e.g. A2m Infotech)
    private readonly itReviewsEn = [
        {
            short: "Great experience with {brand}. Delivered our project right on time without any technical bugs.",
            med: "Approached {brand} for customized software and website development. The team understood our requirements patiently and delivered a very smooth, fast loading platform.",
            long: "We hired {brand} for our company web portal development and SEO setup. Their developers are highly skilled, very cooperative, and quick to resolve revisions. Completely transparent pricing and reliable communication throughout. Highly recommended for web and tech services."
        },
        {
            short: "Very professional tech team at {brand}. Solved our software issues quickly and provided clear documentation.",
            med: "Really happy with the website design and support provided by {brand}. Responsive team, clean coding, and hassle-free delivery.",
            long: "Had an excellent experience partnering with {brand}. They took the time to understand our exact workflow and built a reliable system for our business. Support after delivery has also been prompt and courteous. Deserves a solid 5-star rating."
        },
        {
            short: "Honest and dependable developers. {brand} delivered quality work within our agreed budget.",
            med: "Worked with {brand} on an application upgrade. Great communication, no unnecessary delays, and very courteous team.",
            long: "One of the best IT solution providers we have worked with. {brand} gave us valuable advice on technology choices and delivered ahead of schedule. The application is running smoothly and their team is always available for quick assistance."
        },
        {
            short: "Smooth project execution and excellent technical support from {brand}. Very satisfied.",
            med: "Great web development service by {brand}. Clean UI design, robust backend, and polite team.",
            long: "I reached out to {brand} for our business digital transformation. From the initial consultation to final deployment, everything was handled with great professionalism. Reasonable rates and genuine dedication to quality."
        }
    ];

    private readonly itReviewsHi = [
        {
            short: "{brand} ke sath bohot accha experience raha. Project time par deliver hua aur support bhi prompt mila.",
            med: "Website development ke liye {brand} se contact kiya tha. Team ne saari requirements dhyan se suni aur bina kisi bug ke clean portal bana kar diya.",
            long: "{brand} ki services sach me lajawab hain. Hamari company ke software aur web work me inhone bohot madad ki. Developers kaafi cooperative hain aur pricing bhi genuine hai. Koi hidden charges nahi the, aage bhi inhi se kaam karwayenge."
        },
        {
            short: "Software aur web related kaam ke liye {brand} best choice hai. Quick response aur clean work.",
            med: "{brand} ki team bohot responsive hai. Hamare purane website errors ko inhone turant fix kar diya, highly satisfied.",
            long: "Pehle kisi doosri jagah se kaam karwaya tha par satisfaction nahi mila tha. Fir {brand} se contact kiya, inhone pura system rewrite kiya aur performance double ho gayi. Har step par update dete rahe, 100% recommended."
        },
        {
            short: "Kaam bohot smoothly complete hua. {brand} ka staff aur developers bohot polite hain.",
            med: "Project delivery time par mili aur design bhi modern hai. {brand} par pura trust kiya ja sakta hai.",
            long: "A2m Infotech se software development karwaya, pura experience effortless raha. Team ne patience ke sath sabhi changes kiye aur training bhi acche se di. Best technical agency in the area!"
        }
    ];

    // 2. Healthcare & Clinics
    private readonly healthReviewsEn = [
        {
            short: "Doctor was very calm and attentive. Explained the diagnosis clearly without rushing.",
            med: "Visited {brand} last week. Very clean clinic, courteous reception staff, and minimal waiting time. Doctor explained the prescription patiently.",
            long: "Had a great consultation at {brand}. The doctor listened to my symptoms thoroughly and recommended genuine medication without unnecessary tests. Clinic hygiene was well maintained and staff behavior was very polite. Highly recommended for family healthcare."
        },
        {
            short: "Hygienic setup and gentle treatment. Doctor cleared all my doubts very patiently.",
            med: "Treatment was effective and painless. The clinic staff at {brand} is well organized and supportive.",
            long: "I visited {brand} for dental treatment and was truly impressed with their precision. The doctor made sure I felt comfortable throughout the procedure. Clean instruments, modern equipment, and reasonable consultation fees."
        }
    ];

    private readonly healthReviewsHi = [
        {
            short: "Doctor sahab ka nature bohot humble hai, har baat acche se samjhayi.",
            med: "{brand} me treatment kaafi accha mila. Staff helpful tha aur clinic bilkul neat and clean hai.",
            long: "Pichle hafte {brand} gaya tha, doctor ne bina kisi jaldbazi ke pura checkup kiya aur genuine dawa di. 2 din me hi kaafi aaram mil gaya. Consultation fee bhi bohot reasonable hai, pura parivar yahi jata hai."
        }
    ];

    // 3. Food, Cafe & Restaurants
    private readonly foodReviewsEn = [
        {
            short: "Delicious food, cozy ambiance, and prompt service. Loved the flavors here!",
            med: "Visited {brand} with friends yesterday. The food was fresh, nicely presented, and staff was very attentive throughout our meal.",
            long: "Had a wonderful dining experience at {brand}. The menu has great variety, food was served hot and flavorful, and portion sizes were generous. The staff took good care of our orders and the seating area was clean and welcoming. Definitely visiting again soon."
        },
        {
            short: "Freshly prepared food and great taste. Quality and hygiene both were top notch.",
            med: "Quick table service and lovely atmosphere at {brand}. Highly recommend trying their signature dishes.",
            long: "Great spot for food lovers. We ordered multiple items and each dish exceeded expectations. The staff is polite, waiting time was minimal even on a busy evening, and rates are completely justified for the quality served."
        }
    ];

    private readonly foodReviewsHi = [
        {
            short: "Khana bohot lajawab tha aur service bhi kaafi fast thi. Paisa vasool!",
            med: "{brand} ka taste aur presentation dono shandar hain. Seating area clean hai aur staff bohot polite hai.",
            long: "Weekend par family ke sath {brand} visit kiya tha. Khana bilkul fresh aur garam serve kiya gaya. Taste ekdum authentic tha aur prices bhi reasonable hain. Bacho ko bhi bohot pasand aaya, zaroor dubara aayenge."
        }
    ];

    // 4. Automotive & Garages
    private readonly autoReviewsEn = [
        {
            short: "Quick diagnosis and fair service charges. My vehicle runs like new now.",
            med: "Got my vehicle serviced at {brand}. Skilled mechanics, genuine spare parts used, and delivered on committed time.",
            long: "Honest workshop with knowledgeable technicians. {brand} inspected my vehicle, explained what actually needed repair without pushing unnecessary part replacements, and gave a fair quote. Very satisfied with their transparent work."
        }
    ];

    private readonly autoReviewsHi = [
        {
            short: "Gaadi ki servicing bohot badhiya ki, koi faltu charges nahi lagaye.",
            med: "{brand} ke mechanics kaafi skilled hain. Time par gaadi ready kar di aur sabhi parts genuine dale.",
            long: "Meri gaadi me kafi dino se issue tha jo kisi aur mechanic se solve nahi ho raha tha. {brand} ne ek ghante me fault trace karke fix kar diya. Rates bilkul genuine hain aur staff ka nature bhi helpful hai."
        }
    ];

    // 5. General Businesses / Local Services
    private readonly generalReviewsEn = [
        {
            short: "Smooth and reliable service. The staff at {brand} is courteous and very helpful.",
            med: "Had a hassle-free experience with {brand}. Everything was handled systematically and completed on schedule.",
            long: "Very pleased with the quality of service provided by {brand}. Their team is punctual, communicative, and respectful. They addressed all our queries patiently and delivered exactly what was promised. A dependable place that deserves 5 stars."
        },
        {
            short: "Prompt response and great attention to detail. Will definitely recommend {brand}.",
            med: "Extremely helpful team at {brand}. Honest guidance, fair rates, and smooth execution from start to finish.",
            long: "Visited {brand} after seeing good reviews and my experience was equally positive. Staff was welcoming, no unnecessary waiting, and the work was done to perfection. Refreshing to see such dedicated customer service."
        }
    ];

    private readonly generalReviewsHi = [
        {
            short: "{brand} par service bohot acchi mili. Kaam time par aur bina kisi pareshani ke ho gaya.",
            med: "Pehli baar {brand} visit kiya tha, overall arrangement aur staff ka behavior bohot pasand aaya.",
            long: "Bohot hi cooperative aur professional log hain. Jo commit kiya tha wahi deliver kiya bina kisi delay ke. Pricing bhi transparent thi aur har sawal ka tasalli se jawab diya. Sabhi ko 100% recommend karunga."
        },
        {
            short: "Shaandar service aur polite nature. {brand} is area me sabse best option hai.",
            med: "Kaam bohot acche se nipat gaya. Staff ne pura support diya aur process kaafi smooth thi.",
            long: "Mera personal experience {brand} ke sath bohot badiya raha. Har cheez organized aur well-managed thi. Aage se kisi bhi requirement ke liye yahi contact karunga. Truly 5-star service!"
        }
    ];

    // Additional human sentence builders for exact length scaling
    private readonly humanFillersEn = [
        "Communication was clear and prompt at every stage.",
        "Pricing is very reasonable compared to others in the market.",
        "Really appreciate their polite approach and honest guidance.",
        "They never push unnecessary upsells or hidden costs.",
        "Staff was courteous and made the whole process effortless.",
        "Will definitely recommend them to colleagues and friends."
    ];

    private readonly humanFillersHi = [
        "Inka communication aur response time kaafi fast hai.",
        "Market ke comparison me pricing bhi bohot reasonable aur genuine hai.",
        "Staff ka polite nature aur honest guidance bohot accha laga.",
        "Koi hidden charges ya bina matlab ki fees nahi li.",
        "Har step par transparent rahe, jo commit kiya wahi kiya.",
        "Mai apne dosto aur rishtedaaro ko bhi yahi recommend karunga."
    ];

    // ── Generator Method ────────────────────────────────────────────────────────

    generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const rawBrand = (options as any)?.appName || (options as any)?.businessName || '';
        const brand = cleanBrandName(rawBrand);
        const userPrompt = cleanTopic(options?.topic, brand);
        const language = (options?.language || 'English').toLowerCase();
        const isHindi = language.includes('hindi') || language.includes('hinglish') || language.includes('roman');

        // Target word count bounds (defaults: min 15, max 45, minimum starts from 4 words)
        const minWords = Math.max(4, options?.minWords || 15);
        const maxWords = Math.max(minWords, options?.maxWords || 45);

        const category = this.detectCategory(rawBrand, userPrompt);

        // Select review pool based on category and language
        let pool: { short: string; med: string; long: string }[] = [];

        if (category === 'it_tech') {
            pool = isHindi ? this.itReviewsHi : this.itReviewsEn;
        } else if (category === 'healthcare') {
            pool = isHindi ? this.healthReviewsHi : this.healthReviewsEn;
        } else if (category === 'restaurant_food') {
            pool = isHindi ? this.foodReviewsHi : this.foodReviewsEn;
        } else if (category === 'automotive') {
            pool = isHindi ? this.autoReviewsHi : this.autoReviewsEn;
        } else {
            pool = isHindi ? this.generalReviewsHi : this.generalReviewsEn;
        }

        if (pool.length === 0) {
            pool = isHindi ? this.generalReviewsHi : this.generalReviewsEn;
        }

        const fillers = isHindi ? this.humanFillersHi : this.humanFillersEn;
        const reviews: string[] = [];
        const seen = new Set<string>();

        // Custom prompt adaptation
        let customOpener = '';
        if (userPrompt && userPrompt.length > 3) {
            if (isHindi) {
                customOpener = `${userPrompt} ke liye inki team se contact kiya tha, response bohot badiya mila.`;
            } else {
                customOpener = `Approached them regarding ${userPrompt.toLowerCase()}, and the entire process was smooth.`;
            }
        }

        for (let i = 0; i < count; i++) {
            const templateObj = pool[i % pool.length];

            // Decide base draft depending on desired target word range
            let draft = '';
            const targetAvg = (minWords + maxWords) / 2;

            if (targetAvg <= 18) {
                draft = templateObj.short;
            } else if (targetAvg <= 35) {
                draft = templateObj.med;
            } else {
                draft = templateObj.long;
            }

            // Replace brand placeholder
            const brandLabel = brand && brand.length > 0 ? brand : (isHindi ? 'is company' : 'this place');
            draft = draft.replace(/\{brand\}/g, brandLabel);

            // If user supplied custom prompt and this is every 2nd review, weave it naturally (only if word limit permits)
            if (customOpener && i % 2 === 1 && !draft.includes(userPrompt) && maxWords >= 20) {
                draft = `${customOpener} ${draft}`;
            }

            // Word count adjustment loop
            let words = this.countWords(draft);

            // If below minWords, append a natural human filler sentence (only if allowed by maxWords)
            let fillerIdx = i;
            while (words < minWords && (words + 5) <= maxWords && fillerIdx < fillers.length + i) {
                const addFiller = fillers[fillerIdx % fillers.length];
                if (!draft.includes(addFiller)) {
                    draft = `${draft} ${addFiller}`;
                    words = this.countWords(draft);
                }
                fillerIdx++;
            }

            // If above maxWords, truncate cleanly
            if (words > maxWords) {
                const sentences = draft.match(/[^.!?]+[.!?]+/g) || [draft];
                let trimmed = '';
                for (const s of sentences) {
                    const testTrim = trimmed ? `${trimmed} ${s.trim()}` : s.trim();
                    if (this.countWords(testTrim) <= maxWords) {
                        trimmed = testTrim;
                    } else {
                        break;
                    }
                }
                if (trimmed && this.countWords(trimmed) >= Math.max(3, minWords * 0.7)) {
                    draft = trimmed;
                } else {
                    const w = draft.split(/\s+/).filter(Boolean);
                    draft = w.slice(0, maxWords).join(' ').replace(/[,;:\-]+$/, '').trim() + '.';
                }
            }

            draft = sanitizeReviewText(draft);

            // Deduplication safeguard
            if (seen.has(draft)) {
                const variations = isHindi
                    ? ['Sach me, ', 'Personal visit ke baad bolu toh, ', 'Bina doubt ke, ']
                    : ['Honestly, ', 'From personal experience, ', 'Without hesitation, '];
                draft = `${variations[i % variations.length]}${draft.charAt(0).toLowerCase()}${draft.slice(1)}`;
                draft = sanitizeReviewText(draft);
            }

            seen.add(draft);
            reviews.push(draft);
        }

        return Promise.resolve(reviews);
    }
}
