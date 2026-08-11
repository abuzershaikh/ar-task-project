import { BadRequestException } from '@nestjs/common';

export class PricingPolicy {
    static validateQuantity(quantity: number): void {
        if (!quantity || typeof quantity !== 'number' || quantity <= 0 || !Number.isInteger(quantity)) {
            throw new BadRequestException('Order quantity must be a positive integer');
        }
    }

    static validateCurrency(currency: string): void {
        const supported = ['INR', 'USD', 'EUR'];
        if (!currency || !supported.includes(currency.toUpperCase())) {
            throw new BadRequestException(`Currency '${currency}' is invalid or unsupported`);
        }
    }
}
