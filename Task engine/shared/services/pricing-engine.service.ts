import { Injectable } from '@nestjs/common';
import { PricingEngine } from '../engines/pricing-engine/pricing.engine';

@Injectable()
export class PricingEngineService {
    constructor(private readonly pricingEngine: PricingEngine) { }

    async calculatePriceSnapshot(serviceCode: string, totalTasksRequired: number) {
        return this.pricingEngine.createOrderPriceSnapshot(serviceCode, totalTasksRequired);
    }
}
