import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ServiceCatalogService } from '../../../../shared/modules/service-catalog/services/service-catalog.service';
import { ServicePricingService } from '../../../../shared/modules/service-catalog/services/service-pricing.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Buyer - Service Catalog')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/services')
export class BuyerServiceCatalogController {
    constructor(
        private readonly serviceCatalogService: ServiceCatalogService,
        private readonly servicePricingService: ServicePricingService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all active services in catalog available for purchase' })
    async listActiveServices() {
        const services = await this.serviceCatalogService.getActiveServices();
        const catalogList = [];

        for (const service of services) {
            try {
                // Ensure the service has active pricing before showing to buyers
                const activePricing = await this.servicePricingService.getActivePricing(service.id);
                catalogList.push({
                    id: service.id,
                    code: service.code,
                    name: service.name,
                    description: service.description,
                    elements: service.elements,
                    buyerUnitPrice: activePricing.buyerUnitPrice,
                    currency: activePricing.currency,
                });
            } catch (err) {
                // Skip services that don't have active pricing configured by Admin yet
                continue;
            }
        }

        return {
            success: true,
            services: catalogList,
            total: catalogList.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get specific service details and dynamic elements schema' })
    async getServiceDetails(@Param('id') id: string) {
        let service;
        try {
            service = await this.serviceCatalogService.getServiceById(id);
        } catch {
            service = await this.serviceCatalogService.getServiceByCode(id);
        }

        if (!service || !service.isActive) {
            throw new NotFoundException('Service not found or inactive');
        }

        let activePricing;
        try {
            activePricing = await this.servicePricingService.getActivePricing(service.id);
        } catch {
            throw new NotFoundException('Service is not currently available for purchase (missing pricing)');
        }

        return {
            success: true,
            service: {
                id: service.id,
                code: service.code,
                name: service.name,
                description: service.description,
                elements: service.elements,
                buyerUnitPrice: activePricing.buyerUnitPrice,
                currency: activePricing.currency,
            },
        };
    }
}
