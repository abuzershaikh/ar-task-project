import { Controller, Get, Param, Query, Post, Body } from '@nestjs/common';
import { ServiceTemplateService } from '../services/service-template.service';
import { TemplateRendererService } from '../services/template-renderer.service';
import { PricingCalculatorService } from '../services/pricing-calculator.service';

@Controller('buyer/service-templates')
export class BuyerServiceTemplateController {
  constructor(
    private readonly serviceTemplateService: ServiceTemplateService,
    private readonly templateRendererService: TemplateRendererService,
    private readonly pricingCalculatorService: PricingCalculatorService,
  ) {}

  @Get()
  async getBuyerCatalog() {
    const templates = await this.serviceTemplateService.getAllPublishedTemplates();
    return { success: true, data: templates };
  }

  @Get(':id/render')
  async renderForBuyer(@Param('id') id: string) {
    const template = await this.serviceTemplateService.getTemplateById(id);
    const renderedView = this.templateRendererService.renderForBuyer(template);
    return { success: true, data: { template, renderedView } };
  }

  @Post(':id/calculate-price')
  async calculatePrice(
    @Param('id') id: string,
    @Body() body: { targetQuantity?: number; selectedChipId?: string },
  ) {
    const template = await this.serviceTemplateService.getTemplateById(id);
    const calculation = this.pricingCalculatorService.calculatePrice(
      template.pricing,
      body.targetQuantity,
      body.selectedChipId,
    );
    return { success: true, data: calculation };
  }
}
