import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { ServiceCatalogRepository } from '../../../database/repositories/service-catalog.repository';
import { ServiceCatalog } from '../../../database/entities/service-catalog.entity';

@Injectable()
export class ServiceCatalogService {
    constructor(private readonly serviceCatalogRepo: ServiceCatalogRepository) { }

    async getAllServices(): Promise<ServiceCatalog[]> {
        return this.serviceCatalogRepo.findAll();
    }

    async getActiveServices(): Promise<ServiceCatalog[]> {
        return this.serviceCatalogRepo.findActive();
    }

    async getServiceById(id: string): Promise<ServiceCatalog> {
        const service = await this.serviceCatalogRepo.findById(id);
        if (!service) {
            throw new NotFoundException(`Service with ID '${id}' not found`);
        }
        return service;
    }

    async getServiceByCode(code: string): Promise<ServiceCatalog> {
        const service = await this.serviceCatalogRepo.findByCode(code);
        if (!service) {
            throw new NotFoundException(`Service with code '${code}' not found`);
        }
        return service;
    }

    async createService(data: {
        code: string;
        name: string;
        description?: string;
        category?: string;
        serviceType?: string;
        aiGeneratorEnabled?: boolean;
        aiGeneratorConfig?: any;
        elements?: any;
        reviewMode?: string;
        videoTutorialUrl?: string;
        audioGuideUrl?: string;
        adminInstructions?: string;
        linkFieldLabel?: string;
        linkFieldPlaceholder?: string;
        textFieldLabel?: string;
        textFieldPlaceholder?: string;
        watchtimeSeconds?: number;
        watchTimeOptions?: any;
        minCompleteHours?: number;
        maxCompleteHours?: number;
        minAcceptHours?: number;
        maxAcceptHours?: number;
        workerLimit?: number;
    }): Promise<ServiceCatalog> {
        const existing = await this.serviceCatalogRepo.findByCode(data.code);
        if (existing) {
            throw new BadRequestException(`Service with code '${data.code.toUpperCase()}' already exists`);
        }

        return this.serviceCatalogRepo.create({
            code: data.code.toUpperCase(),
            name: data.name,
            description: data.description,
            category: data.category || 'YouTube',
            serviceType: data.serviceType || 'like',
            aiGeneratorEnabled: data.aiGeneratorEnabled ?? false,
            aiGeneratorConfig: data.aiGeneratorConfig,
            elements: data.elements,
            reviewMode: data.reviewMode || 'buyer',
            workerLimit: data.workerLimit || 1,
            videoTutorialUrl: data.videoTutorialUrl,
            audioGuideUrl: data.audioGuideUrl,
            adminInstructions: data.adminInstructions,
            linkFieldLabel: data.linkFieldLabel || 'Target Link / URL',
            linkFieldPlaceholder: data.linkFieldPlaceholder || 'https://...',
            textFieldLabel: data.textFieldLabel || 'Custom Text / Instructions',
            textFieldPlaceholder: data.textFieldPlaceholder || 'Enter text, comments or keywords...',
            watchtimeSeconds: data.watchtimeSeconds || 0,
            watchTimeOptions: data.watchTimeOptions,
            minCompleteHours: data.minCompleteHours || 24,
            maxCompleteHours: data.maxCompleteHours || 72,
            minAcceptHours: data.minAcceptHours || 1,
            maxAcceptHours: data.maxAcceptHours || 24,
            isActive: true,
            version: 1,
        });
    }

    async updateService(
        id: string,
        data: {
            name?: string;
            description?: string;
            category?: string;
            serviceType?: string;
            aiGeneratorEnabled?: boolean;
            aiGeneratorConfig?: any;
            isActive?: boolean;
            elements?: any;
            reviewMode?: string;
            workerLimit?: number;
            videoTutorialUrl?: string;
            audioGuideUrl?: string;
            adminInstructions?: string;
            linkFieldLabel?: string;
            linkFieldPlaceholder?: string;
            textFieldLabel?: string;
            textFieldPlaceholder?: string;
            watchtimeSeconds?: number;
            watchTimeOptions?: any;
            minCompleteHours?: number;
            maxCompleteHours?: number;
            minAcceptHours?: number;
            maxAcceptHours?: number;
        },
    ): Promise<ServiceCatalog> {
        await this.getServiceById(id);
        const updated = await this.serviceCatalogRepo.update(id, data);
        return updated!;
    }

    async softDeleteService(id: string): Promise<boolean> {
        await this.getServiceById(id); // throws NotFoundException if not found
        return this.serviceCatalogRepo.softDelete(id);
    }
}

