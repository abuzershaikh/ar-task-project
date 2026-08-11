import { MarginCalculator } from '../engines/pricing-engine/margin-calculator';
import { RewardCalculator } from '../engines/pricing-engine/reward-calculator';
import { PriceCalculator } from '../engines/pricing-engine/price-calculator';
import { MarginPolicy } from '../engines/pricing-engine/policies/margin-policy';
import { MarginType } from '../modules/service-catalog/enums/margin-type.enum';

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

        it('should throw BadRequestException if buyer price is zero or negative', () => {
            expect(() => {
                MarginPolicy.validateMargin(0, MarginType.FIXED, 5);
            }).toThrow();
        });
    });
});
