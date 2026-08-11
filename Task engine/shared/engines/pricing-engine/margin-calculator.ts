import { Injectable } from '@nestjs/common';
import { MarginType } from '../../modules/service-catalog/enums/margin-type.enum';

@Injectable()
export class MarginCalculator {
    calculateMarginAmount(buyerUnitPrice: number, marginType: MarginType, marginValue: number): number {
        const price = Number(buyerUnitPrice);
        const val = Number(marginValue);

        if (marginType === MarginType.FIXED) {
            return Math.min(price, val);
        }

        if (marginType === MarginType.PERCENTAGE) {
            const calculated = (price * val) / 100;
            return Math.min(price, calculated);
        }

        return 0;
    }
}
