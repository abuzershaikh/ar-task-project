import { PricingModelType } from '../enums/pricing-model-type.enum';

export interface IPriceChip {
  id: string;
  label: string;
  quantity: number;
  price: number;
  isPopular?: boolean;
}

export interface IPricingConfig {
  modelType: PricingModelType;
  buyerPrice: number;
  unitPrice?: number;
  minQuantity?: number;
  maxQuantity?: number;
  adminMarginPercent: number;
  workerReward: number;
  chips?: IPriceChip[];
}
