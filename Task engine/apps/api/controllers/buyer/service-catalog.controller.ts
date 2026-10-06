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
            let unitPrice = 50.0;
            let workerReward = 4.0;
            let marginType = 'PERCENTAGE';
            let marginValue = 20.0;
            let currency = 'INR';

            try {
                const activePricing = await this.servicePricingService.getActivePricing(service.id);
                if (activePricing) {
                    unitPrice = Number(activePricing.buyerUnitPrice) || 50.0;
                    workerReward = Number(activePricing.workerReward) || 4.0;
                    marginType = activePricing.marginType || 'PERCENTAGE';
                    marginValue = Number(activePricing.marginValue) || 20.0;
                    currency = activePricing.currency || 'INR';
                }
            } catch (err) {
                // Fallback default pricing for newly created admin services
            }

            const codeUpper = (service.code || '').toUpperCase();
            const nameUpper = (service.name || '').toUpperCase();
            const catUpper = (service.category || '').toUpperCase();
            const isYouTubeCombo = codeUpper === 'YOUTUBE_COMBO' ||
                codeUpper === 'YT_COMBO' ||
                ((codeUpper.includes('COMBO') || nameUpper.includes('COMBO')) &&
                    (codeUpper.includes('YT') || codeUpper.includes('YOUTUBE') || catUpper.includes('YOUTUBE')));

            let extraPricePerMinute = 0;
            if (isYouTubeCombo) {
                extraPricePerMinute = 0.50;
                if (service.watchTimeOptions) {
                    let parsed = service.watchTimeOptions;
                    if (typeof parsed === 'string') {
                        try { parsed = JSON.parse(parsed); } catch (_) {}
                    }
                    if (parsed && typeof parsed === 'object' && parsed.extraPricePerMinute !== undefined) {
                        extraPricePerMinute = Number(parsed.extraPricePerMinute);
                    }
                }
            }

            catalogList.push({
                id: service.id,
                code: service.code,
                name: service.name,
                description: service.description,
                category: service.category || 'YouTube',
                serviceType: service.serviceType || 'like',
                isActive: service.isActive ?? true,
                aiGeneratorEnabled: Boolean(service.aiGeneratorEnabled),
                aiGeneratorConfig: service.aiGeneratorConfig,
                elements: service.elements,
                buyerUnitPrice: unitPrice,
                currency: currency,
                extraPricePerMinute: extraPricePerMinute,
                pricing: {
                    modelType: 'fixed',
                    buyerPrice: unitPrice,
                    unitPrice: unitPrice,
                    adminMarginPercent: marginValue,
                    workerReward: workerReward,
                    marginType: marginType,
                    minQuantity: 1,
                    maxQuantity: 10000,
                    chips: [],
                    extraPricePerMinute: extraPricePerMinute,
                },
                minAcceptHours: service.minAcceptHours || 1,
                maxAcceptHours: service.maxAcceptHours || 72,
                minCompleteHours: service.minCompleteHours || 1,
                maxCompleteHours: service.maxCompleteHours || 168,
                watchtimeSeconds: isYouTubeCombo ? (service.watchtimeSeconds || 0) : 0,
                watchTimeOptions: isYouTubeCombo ? (service.watchTimeOptions || { extraPricePerMinute, baseMinutes: 5 }) : null,
                videoTutorialUrl: service.videoTutorialUrl,
                audioGuideUrl: service.audioGuideUrl,
                adminInstructions: service.adminInstructions,
                linkFieldLabel: service.linkFieldLabel || 'Target Link / URL',
                linkFieldPlaceholder: service.linkFieldPlaceholder || 'https://...',
                textFieldLabel: service.textFieldLabel || 'Custom Text / Instructions',
                textFieldPlaceholder: service.textFieldPlaceholder || 'Enter comments, text, or instructions...',
            });
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

        let unitPrice = 50.0;
        let workerReward = 4.0;
        let marginType = 'PERCENTAGE';
        let marginValue = 20.0;
        let currency = 'INR';

        try {
            const activePricing = await this.servicePricingService.getActivePricing(service.id);
            if (activePricing) {
                unitPrice = Number(activePricing.buyerUnitPrice) || 50.0;
                workerReward = Number(activePricing.workerReward) || 4.0;
                marginType = activePricing.marginType || 'PERCENTAGE';
                marginValue = Number(activePricing.marginValue) || 20.0;
                currency = activePricing.currency || 'INR';
            }
        } catch {
            // Keep default fallback
        }

        const codeUpper = (service.code || '').toUpperCase();
        const nameUpper = (service.name || '').toUpperCase();
        const catUpper = (service.category || '').toUpperCase();
        const isYouTubeCombo = codeUpper === 'YOUTUBE_COMBO' ||
            codeUpper === 'YT_COMBO' ||
            ((codeUpper.includes('COMBO') || nameUpper.includes('COMBO')) &&
                (codeUpper.includes('YT') || codeUpper.includes('YOUTUBE') || catUpper.includes('YOUTUBE')));

        let extraPricePerMinute = 0;
        if (isYouTubeCombo) {
            extraPricePerMinute = 0.50;
            if (service.watchTimeOptions) {
                let parsed = service.watchTimeOptions;
                if (typeof parsed === 'string') {
                    try { parsed = JSON.parse(parsed); } catch (_) {}
                }
                if (parsed && typeof parsed === 'object' && parsed.extraPricePerMinute !== undefined) {
                    extraPricePerMinute = Number(parsed.extraPricePerMinute);
                }
            }
        }

        return {
            success: true,
            service: {
                id: service.id,
                code: service.code,
                name: service.name,
                description: service.description,
                elements: service.elements,
                buyerUnitPrice: unitPrice,
                currency: currency,
                extraPricePerMinute: extraPricePerMinute,
                pricing: {
                    modelType: 'fixed',
                    buyerPrice: unitPrice,
                    unitPrice: unitPrice,
                    adminMarginPercent: marginValue,
                    workerReward: workerReward,
                    marginType: marginType,
                    minQuantity: 1,
                    maxQuantity: 10000,
                    chips: [],
                    extraPricePerMinute: extraPricePerMinute,
                },
                watchtimeSeconds: isYouTubeCombo ? (service.watchtimeSeconds || 0) : 0,
                watchTimeOptions: isYouTubeCombo ? (service.watchTimeOptions || { extraPricePerMinute, baseMinutes: 5 }) : null,
                videoTutorialUrl: service.videoTutorialUrl,
                audioGuideUrl: service.audioGuideUrl,
                adminInstructions: service.adminInstructions,
                linkFieldLabel: service.linkFieldLabel || 'Target Link / URL',
                linkFieldPlaceholder: service.linkFieldPlaceholder || 'https://...',
                textFieldLabel: service.textFieldLabel || 'Custom Text / Instructions',
                textFieldPlaceholder: service.textFieldPlaceholder || 'Enter comments, text, or instructions...',
            },
        };
    }
}
