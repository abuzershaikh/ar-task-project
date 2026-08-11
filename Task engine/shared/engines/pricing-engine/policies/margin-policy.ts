import { BadRequestException } from '@nestjs/common';
import { MarginType } from '../../../modules/service-catalog/enums/margin-type.enum';

export class MarginPolicy {
    static validateMargin(buyerUnitPrice: number, marginType: MarginType, marginValue: number): void {
        if (buyerUnitPrice <= 0) {
            throw new BadRequestException('buyerUnitPrice must be greater than 0');
        }

        if (marginValue < 0) {
            throw new BadRequestException('marginValue cannot be negative');
        }

        let marginAmount = 0;
        if (marginType === MarginType.FIXED) {
            marginAmount = marginValue;
        } else if (marginType === MarginType.PERCENTAGE) {
            marginAmount = (buyerUnitPrice * marginValue) / 100;
        } else {
            throw new BadRequestException(`Unsupported marginType '${marginType}'`);
        }

        if (marginAmount > buyerUnitPrice) {
            throw new BadRequestException(
                `Calculated margin (₹${marginAmount.toFixed(2)}) exceeds buyer unit price (₹${buyerUnitPrice.toFixed(2)})`,
            );
        }

        const workerReward = buyerUnitPrice - marginAmount;
        if (workerReward < 0) {
            throw new BadRequestException('Worker reward cannot become negative');
        }
    }
}
