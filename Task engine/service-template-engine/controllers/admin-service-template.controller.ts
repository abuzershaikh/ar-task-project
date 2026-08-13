import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { ServiceTemplateService, IServiceTemplate } from '../services/service-template.service';

@Controller('admin/service-templates')
export class AdminServiceTemplateController {
  constructor(private readonly serviceTemplateService: ServiceTemplateService) {}

  @Get()
  async getAllTemplates() {
    const templates = await this.serviceTemplateService.getAllPublishedTemplates();
    return { success: true, count: templates.length, data: templates };
  }

  @Get(':id')
  async getTemplateById(@Param('id') id: string) {
    const template = await this.serviceTemplateService.getTemplateById(id);
    return { success: true, data: template };
  }

  @Post()
  async saveTemplate(@Body() body: Partial<IServiceTemplate>) {
    const saved = await this.serviceTemplateService.saveTemplate(body);
    return { success: true, message: 'Service template saved successfully', data: saved };
  }
}
