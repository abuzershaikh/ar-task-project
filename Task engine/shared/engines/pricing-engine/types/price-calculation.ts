import { MarginType } from '../../../modules/service-catalog/enums/margin-type.enum';

export interface PriceCalculationRequest {
    serviceCode: string;
    quantity: number;
}

export interface BuyerPriceInformation {
    serviceCode: string;
    serviceName: string;
    buyerUnitPrice: number;
    currency: string;
    quantity: number;
    totalAmount: number;
}

export interface InternalFinancialCalculation {
    serviceId: string;
    serviceCode: string;
    serviceName: string;
    buyerUnitPrice: number;
    marginType: MarginType;
    marginValue: number;
    marginAmount: number;
    workerReward: number;
    currency: string;
    pricingVersion: number;
    quantity: number;
    totalBuyerAmount: number;
    totalWorkerPayout: number;
    totalPlatformRevenue: number;
}
