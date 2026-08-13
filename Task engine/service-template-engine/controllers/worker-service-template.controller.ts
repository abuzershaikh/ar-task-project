import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { ServiceTemplateService } from '../services/service-template.service';
import { TemplateRendererService } from '../services/template-renderer.service';

@Controller('worker/service-templates')
export class WorkerServiceTemplateController {
  constructor(
    private readonly serviceTemplateService: ServiceTemplateService,
    private readonly templateRendererService: TemplateRendererService,
  ) {}

  @Get(':id/render')
  async renderForWorker(@Param('id') id: string) {
    const template = await this.serviceTemplateService.getTemplateById(id);
    const renderedView = this.templateRendererService.renderForWorker(template);
    return { success: true, data: { template, renderedView } };
  }

  @Post(':id/render-with-payload')
  async renderWithPayload(
    @Param('id') id: string,
    @Body() body: { payloadData?: Record<string, any> },
  ) {
    const template = await this.serviceTemplateService.getTemplateById(id);
    const renderedView = this.templateRendererService.renderForWorker(template, body.payloadData);
    return { success: true, data: { template, renderedView } };
  }
}
