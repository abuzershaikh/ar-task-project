import { MarginType } from '../../../modules/service-catalog/enums/margin-type.enum';

export interface PriceSnapshot {
    serviceId: string;
    serviceCode: string;
    pricingVersion: number;
    buyerUnitPrice: number;
    marginType: MarginType;
    marginValue: number;
    marginAmount: number;
    workerRewardSnapshot: number;
    currency: string;
    quantity: number;
    totalAmount: number;
    snapshotCreatedAt: Date;
}
