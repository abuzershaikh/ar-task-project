import { Injectable } from '@nestjs/common';
import { PricingPolicy } from './policies/pricing-policy';

@Injectable()
export class PriceCalculator {
    calculateBuyerTotal(buyerUnitPrice: number, quantity: number): number {
        PricingPolicy.validateQuantity(quantity);
        return Number(buyerUnitPrice) * quantity;
    }
}
