import { Injectable } from '@nestjs/common';
import { IContentGenerator, GenerationOptions } from './generator.interface';

@Injectable()
export class PlayStoreReviewGenerator implements IContentGenerator {

    private readonly praiseEn = [
        'Fantastic app! The UI is incredibly smooth and easy to navigate.',
        'Hands down the best app in this category. Very clean interface and zero lags.',
        'Extremely useful application. Works like a charm and saves me so much time.',
        'Super fast, lightweight and responsive. The developers did an outstanding job!',
        'Top notch user experience! Everything works seamlessly right out of the box.',
        'Highly recommended! Great feature set and very reliable performance.',
        'Brilliant concept and flawless execution. Worth all 5 stars ⭐⭐⭐⭐⭐',
        'Clean design, fast loading speeds, and very intuitive navigation. Loved it!',
        'One of the cleanest and most polished Android apps I have ever used.',
        'Super easy to use and very well optimized for all devices.',
        'Wonderful app with top tier design and great utility. A solid 5-star rating from me!',
        'Really impressed with the quality and responsiveness. Keep up the excellent work!',
        'Everything is neat, intuitive, and works exactly as advertised.',
        'Terrific app! Smooth performance, no bugs encountered so far.',
        'I have tried many similar apps, but this one is definitely the best.'
    ];

    private readonly topicSpecificEn = [
        'particularly love how {topic} is implemented so smoothly',
        'the feature for {topic} is super handy and reliable',
        'especially impressed with {topic}, works effortlessly',
        'the performance regarding {topic} is top class',
        'everything about {topic} is well thought out and polished',
        'very pleased with the {topic} experience'
    ];

    private readonly closersEn = [
        'Highly recommended to everyone! ⭐⭐⭐⭐⭐',
        'Kudos to the developers for this amazing app!',
        'Must-have app on every Android device.',
        'Giving a full 5 stars, keep it up!',
        'Worth every bit, 5 stars all the way!',
        'Will definitely recommend this to friends and colleagues 👍'
    ];

    private readonly praiseHi = [
        'Bohot hi badhiya aur useful application hai ⭐⭐⭐⭐⭐',
        'Ekdum smooth chal raha hai, UI bohot clean aur fast hai.',
        'Kamaal ka app hai, use karna bohot aasan hai.',
        'Bohot accha user experience mila, bilkul lag nahi karta.',
        'Top class app, sabhi features bohot acche se kaam kar rahe hain.',
        'Shaandar design aur super fast performance! 5 stars 👍',
        'Abhi tak ka sabse best app hai is category me.',
        'Bohot helpful app hai, download karke maza aa gaya.'
    ];

    private readonly closersHi = [
        'Sabhi ko zaroor recommend karunga! 5 stars ⭐⭐⭐⭐⭐',
        'Developers ko bohot bohot shukriya itna accha app banane ke liye.',
        'Full 5-star rating! Zabardast work 👍',
        'Highly recommended, zaroor try karein!'
    ];
    async generateBatch(count: number, options?: GenerationOptions): Promise<string[]> {
        const appName = options?.appName?.trim() || '';
        const rawTopic = options?.topic?.trim() || '';
        const topic = appName ? (rawTopic ? `${appName} - ${rawTopic}` : appName) : rawTopic;
        const language = (options?.language || 'English').toLowerCase();
        const isHindi = language.includes('hindi') || language.includes('hinglish');

        const results = new Set<string>();
        let attempts = 0;
        const maxAttempts = count * 20;

        while (results.size < count && attempts < maxAttempts) {
            attempts++;
            let reviewText = '';

            if (isHindi) {
                const p = this.praiseHi[Math.floor(Math.random() * this.praiseHi.length)];
                const c = this.closersHi[Math.floor(Math.random() * this.closersHi.length)];
                if (topic && Math.random() > 0.4) {
                    reviewText = `${p} ${topic} ke liye best hai. ${c}`;
                } else {
                    reviewText = `${p} ${c}`;
                }
            } else {
                const p = this.praiseEn[Math.floor(Math.random() * this.praiseEn.length)];
                const c = this.closersEn[Math.floor(Math.random() * this.closersEn.length)];
                if (topic && Math.random() > 0.3) {
                    const t = this.topicSpecificEn[Math.floor(Math.random() * this.topicSpecificEn.length)]
                        .replace('{topic}', topic);
                    reviewText = `${p} ${t}. ${c}`;
                } else {
                    reviewText = `${p} ${c}`;
                }
            }

            results.add(reviewText.trim());
        }

        const list = Array.from(results);
        while (list.length < count) {
            list.push(`Great app, very smooth and intuitive! Highly recommended. ⭐⭐⭐⭐⭐ (Ref #${list.length + 1})`);
        }

        return list.slice(0, count);
    }
}
