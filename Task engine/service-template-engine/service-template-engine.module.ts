import { Module } from '@nestjs/common';
import { ServiceTemplateService } from './services/service-template.service';
import { TemplateRendererService } from './services/template-renderer.service';
import { PricingCalculatorService } from './services/pricing-calculator.service';
import { AdminServiceTemplateController } from './controllers/admin-service-template.controller';
import { BuyerServiceTemplateController } from './controllers/buyer-service-template.controller';
import { WorkerServiceTemplateController } from './controllers/worker-service-template.controller';

@Module({
  controllers: [
    AdminServiceTemplateController,
    BuyerServiceTemplateController,
    WorkerServiceTemplateController,
  ],
  providers: [
    ServiceTemplateService,
    TemplateRendererService,
    PricingCalculatorService,
  ],
  exports: [
    ServiceTemplateService,
    TemplateRendererService,
    PricingCalculatorService,
  ],
})
export class ServiceTemplateEngineModule {}
