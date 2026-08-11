import {
    Controller,
    Get,
    Post,
    Patch,
    Param,
    Body,
    Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { ServiceCatalogService } from '../../../../shared/modules/service-catalog/services/service-catalog.service';
import { ServicePricingService } from '../../../../shared/modules/service-catalog/services/service-pricing.service';
import { PricingEngine } from '../../../../shared/engines/pricing-engine/pricing.engine';
import { MarginType } from '../../../../shared/modules/service-catalog/enums/margin-type.enum';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Service Catalog & Pricing Engine')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/services')
export class AdminServiceCatalogController {
    constructor(
        private readonly serviceCatalogService: ServiceCatalogService,
        private readonly servicePricingService: ServicePricingService,
        private readonly pricingEngine: PricingEngine,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all services in catalog with active pricing' })
    async listServices() {
        const services = await this.serviceCatalogService.getAllServices();
        const catalogList = [];

        for (const service of services) {
            let activePricing = null;
            try {
                activePricing = await this.servicePricingService.getActivePricing(service.id);
            } catch {
                activePricing = null;
            }
            catalogList.push({
                service,
                activePricing,
            });
        }

        return {
            success: true,
            services: catalogList,
            total: catalogList.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get service details with active pricing version' })
    async getService(@Param('id') id: string) {
        const service = await this.serviceCatalogService.getServiceById(id);
        let activePricing = null;
        try {
            activePricing = await this.servicePricingService.getActivePricing(service.id);
        } catch {
            activePricing = null;
        }

        return {
            success: true,
            service,
            activePricing,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Create new service catalog definition' })
    async createService(
        @Body()
        body: {
            code: string;
            name: string;
            description?: string;
            buyerUnitPrice?: number;
            marginType?: MarginType;
            marginValue?: number;
        },
    ) {
        const service = await this.serviceCatalogService.createService({
            code: body.code,
            name: body.name,
            description: body.description,
        });

        let initialPricing = null;
        if (body.buyerUnitPrice && body.marginValue !== undefined) {
            initialPricing = await this.servicePricingService.createNewPricingVersion(service.id, {
                buyerUnitPrice: body.buyerUnitPrice,
                marginType: body.marginType || MarginType.FIXED,
                marginValue: body.marginValue,
            });
        }

        return {
            success: true,
            service,
            initialPricing,
            message: 'Service catalog definition created successfully',
        };
    }

    @Patch(':id')
    @ApiOperation({ summary: 'Update service catalog metadata (name, description, active state)' })
    async updateService(
        @Param('id') id: string,
        @Body() body: { name?: string; description?: string; isActive?: boolean },
    ) {
        const service = await this.serviceCatalogService.updateService(id, body);
        return {
            success: true,
            service,
            message: 'Service catalog updated',
        };
    }

    @Post(':id/pricing')
    @ApiOperation({ summary: 'Create new pricing version for service (Validates margin policies)' })
    async createPricing(
        @Param('id') serviceId: string,
        @Body()
        body: {
            buyerUnitPrice: number;
            marginType: MarginType;
            marginValue: number;
            currency?: string;
        },
    ) {
        const pricing = await this.servicePricingService.createNewPricingVersion(serviceId, body);
        return {
            success: true,
            pricing,
            message: `New pricing version ${pricing.version} created and activated for service`,
        };
    }

    @Get(':id/pricing/history')
    @ApiOperation({ summary: 'Get historical pricing version list for service' })
    async getPricingHistory(@Param('id') serviceId: string) {
        const history = await this.servicePricingService.getPricingHistory(serviceId);
        return {
            success: true,
            serviceId,
            history,
            totalVersions: history.length,
        };
    }

    @Get(':id/financials')
    @ApiOperation({ summary: 'Calculate sample financial breakdown for quantity (Admin internal)' })
    @ApiQuery({ name: 'quantity', required: true, type: Number })
    async calculateFinancials(
        @Param('id') serviceId: string,
        @Query('quantity') quantity: number,
    ) {
        const financials = await this.pricingEngine.calculateFullFinancials(serviceId, Number(quantity || 100));
        return {
            success: true,
            financials,
        };
    }
}
