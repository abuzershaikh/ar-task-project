import { Injectable } from '@nestjs/common';
import { MarginType } from '../../modules/service-catalog/enums/margin-type.enum';

@Injectable()
export class MarginCalculator {
    calculateMarginAmount(buyerUnitPrice: number, marginType: MarginType | string, marginValue: number): number {
        const price = Number(buyerUnitPrice);
        const val = Number(marginValue);
        const type = String(marginType || '').toUpperCase();

        if (type === MarginType.FIXED || type === 'FIXED') {
            return Math.min(price, val);
        }

        if (type === MarginType.PERCENTAGE || type === 'PERCENTAGE') {
            const calculated = (price * val) / 100;
            return Math.min(price, calculated);
        }

        return 0;
    }
}
