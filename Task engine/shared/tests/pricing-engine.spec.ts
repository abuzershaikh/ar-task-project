import { MarginCalculator } from '../engines/pricing-engine/margin-calculator';
import { RewardCalculator } from '../engines/pricing-engine/reward-calculator';
import { PriceCalculator } from '../engines/pricing-engine/price-calculator';
import { MarginPolicy } from '../engines/pricing-engine/policies/margin-policy';
import { MarginType } from '../modules/service-catalog/enums/margin-type.enum';
import { calculateYouTubeDurationPricing } from '../engines/pricing-engine/youtube-duration-pricing';

describe('Pricing Engine & Service Catalog Calculations', () => {
    let marginCalculator: MarginCalculator;
    let rewardCalculator: RewardCalculator;
    let priceCalculator: PriceCalculator;

    beforeEach(() => {
        marginCalculator = new MarginCalculator();
        rewardCalculator = new RewardCalculator(marginCalculator);
        priceCalculator = new PriceCalculator();
    });

    describe('FIXED Margin Calculations', () => {
        it('should correctly calculate fixed margin and worker reward', () => {
            const buyerPrice = 50;
            const marginValue = 10;
            const result = rewardCalculator.calculateWorkerReward(buyerPrice, MarginType.FIXED, marginValue);

            expect(result.buyerUnitPrice).toBe(50);
            expect(result.marginAmount).toBe(10);
            expect(result.workerFinalReward).toBe(40);
            expect(result.isValid).toBe(true);
        });
    });

    describe('PERCENTAGE Margin Calculations', () => {
        it('should correctly calculate 25% margin on ₹20 buyer price', () => {
            const buyerPrice = 20;
            const marginValue = 25; // 25%
            const result = rewardCalculator.calculateWorkerReward(buyerPrice, MarginType.PERCENTAGE, marginValue);

            expect(result.buyerUnitPrice).toBe(20);
            expect(result.marginAmount).toBe(5);
            expect(result.workerFinalReward).toBe(15);
            expect(result.isValid).toBe(true);
        });
    });

    describe('Server-Authoritative Price Calculation', () => {
        it('should calculate 500 tasks at ₹10 = ₹5,000', () => {
            const total = priceCalculator.calculateBuyerTotal(10, 500);
            expect(total).toBe(5000);
        });
    });

    describe('MarginPolicy Validation Rules', () => {
        it('should throw BadRequestException if margin exceeds buyer price', () => {
            expect(() => {
                MarginPolicy.validateMargin(20, MarginType.FIXED, 25);
            }).toThrow();
        });

        it('should reject a 100% margin because the worker must receive a positive reward', () => {
            expect(() => {
                MarginPolicy.validateMargin(20, MarginType.PERCENTAGE, 100);
            }).toThrow();
        });

        it('should throw BadRequestException if buyer price is zero or negative', () => {
            expect(() => {
                MarginPolicy.validateMargin(0, MarginType.FIXED, 5);
            }).toThrow();
        });
    });

    describe('YouTube duration pricing', () => {
        it('keeps the configured percentage worker share for extra watch time', () => {
            const result = calculateYouTubeDurationPricing({
                baseBuyerUnitPrice: 2.00,
                baseWorkerReward: 1.50,
                marginType: MarginType.PERCENTAGE,
                watchTimeSeconds: 8 * 60,
                extraPricePerMinute: 0.50,
            });

            expect(result).toEqual({
                extraMinutes: 3,
                extraPerUnit: 1.50,
                buyerUnitPrice: 3.50,
                workerReward: 2.63,
                platformMargin: 0.87,
            });
        });

        it('keeps a fixed platform fee fixed for extra watch time', () => {
            const result = calculateYouTubeDurationPricing({
                baseBuyerUnitPrice: 2.00,
                baseWorkerReward: 1.50,
                marginType: MarginType.FIXED,
                watchTimeSeconds: 8 * 60,
                extraPricePerMinute: 0.50,
            });

            expect(result.workerReward).toBe(3.00);
            expect(result.platformMargin).toBe(0.50);
        });

        it('does not add a charge at or below the included five minutes', () => {
            const result = calculateYouTubeDurationPricing({
                baseBuyerUnitPrice: 2.00,
                baseWorkerReward: 1.50,
                marginType: MarginType.PERCENTAGE,
                watchTimeSeconds: 300,
                extraPricePerMinute: 0.50,
            });

            expect(result.extraMinutes).toBe(0);
            expect(result.buyerUnitPrice).toBe(2.00);
            expect(result.workerReward).toBe(1.50);
        });

        it('handles case-insensitive and partial marginType strings gracefully without crashing', () => {
            const resultPercentage = calculateYouTubeDurationPricing({
                baseBuyerUnitPrice: 2.00,
                baseWorkerReward: 1.50,
                marginType: 'percent',
                watchTimeSeconds: 480,
                extraPricePerMinute: 0.50,
            });
            expect(resultPercentage.workerReward).toBe(2.63);
            expect(resultPercentage.platformMargin).toBe(0.87);

            const resultFixed = calculateYouTubeDurationPricing({
                baseBuyerUnitPrice: 2.00,
                baseWorkerReward: 1.50,
                marginType: 'fixed_fee',
                watchTimeSeconds: 480,
                extraPricePerMinute: 0.50,
            });
            expect(resultFixed.workerReward).toBe(3.00);
            expect(resultFixed.platformMargin).toBe(0.50);
        });

        it('correctly calculates 60-minute maximum watch duration without rounding drift', () => {
            const result = calculateYouTubeDurationPricing({
                baseBuyerUnitPrice: 2.00,
                baseWorkerReward: 1.50,
                marginType: MarginType.PERCENTAGE,
                watchTimeSeconds: 60 * 60, // 60 minutes (55 extra minutes)
                extraPricePerMinute: 0.50,
            });

            expect(result.extraMinutes).toBe(55);
            expect(result.extraPerUnit).toBe(27.50);
            expect(result.buyerUnitPrice).toBe(29.50);
            // Worker receives 75% of total: 29.50 * 0.75 = 22.125 -> 22.13
            expect(result.workerReward).toBe(22.13);
            // Platform receives 29.50 - 22.13 = 7.37
            expect(result.platformMargin).toBe(7.37);
            // Total worker + platform equals buyer unit price exactly
            expect(result.workerReward + result.platformMargin).toBe(result.buyerUnitPrice);
        });
    });
});
