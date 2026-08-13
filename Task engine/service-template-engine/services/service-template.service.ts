import { Injectable, NotFoundException } from '@nestjs/common';
import { IPricingConfig } from '../domain/interfaces/pricing-config.interface';
import { ITemplateElement } from '../domain/interfaces/template-element.interface';
import { PricingModelType } from '../domain/enums/pricing-model-type.enum';
import { VisibilityContext } from '../domain/enums/visibility-context.enum';
import { EditabilityMode } from '../domain/enums/editability-mode.enum';
import { ElementType } from '../domain/enums/element-type.enum';

export interface IServiceTemplate {
  id: string;
  code: string;
  name: string;
  description: string;
  isActive: boolean;
  pricing: IPricingConfig;
  elements: ITemplateElement[];
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class ServiceTemplateService {
  private templatesStore: Map<string, IServiceTemplate> = new Map();

  constructor() {
    this.seedDefaultTemplates();
  }

  /**
   * Get all published service templates
   */
  async getAllPublishedTemplates(): Promise<IServiceTemplate[]> {
    return Array.from(this.templatesStore.values()).filter((t) => t.isActive);
  }

  /**
   * Get template by ID
   */
  async getTemplateById(id: string): Promise<IServiceTemplate> {
    const template = this.templatesStore.get(id);
    if (!template) {
      throw new NotFoundException(`Service template with ID ${id} not found.`);
    }
    return template;
  }

  /**
   * Create or update service template (Admin Studio)
   */
  async saveTemplate(templateData: Partial<IServiceTemplate>): Promise<IServiceTemplate> {
    const id = templateData.id || `srv_${Date.now()}`;
    const existing = this.templatesStore.get(id);

    const updatedTemplate: IServiceTemplate = {
      id,
      code: templateData.code || existing?.code || 'CUSTOM_SERVICE',
      name: templateData.name || existing?.name || 'Custom Service',
      description: templateData.description || existing?.description || '',
      isActive: templateData.isActive !== undefined ? templateData.isActive : true,
      pricing: templateData.pricing || existing?.pricing || {
        modelType: PricingModelType.FIXED,
        buyerPrice: 199.0,
        adminMarginPercent: 20.0,
        workerReward: 159.2,
      },
      elements: templateData.elements || existing?.elements || [],
      createdAt: existing?.createdAt || new Date(),
      updatedAt: new Date(),
    };

    this.templatesStore.set(id, updatedTemplate);
    return updatedTemplate;
  }

  /**
   * Seed default Admin Service Templates
   */
  private seedDefaultTemplates() {
    // 1. YouTube Subscribers Template with Price Chips
    this.templatesStore.set('srv_yt_subs', {
      id: 'srv_yt_subs',
      code: 'YOUTUBE_SUBSCRIBE',
      name: 'YouTube Channel Subscribers',
      description: 'Get real organic Subscribers for your YouTube channel with high retention.',
      isActive: true,
      pricing: {
        modelType: PricingModelType.TIERED_CHIPS,
        buyerPrice: 199.0,
        adminMarginPercent: 20.0,
        workerReward: 159.2,
        chips: [
          { id: 'chip_1', label: '100 Subscribers', quantity: 100, price: 199.0 },
          { id: 'chip_2', label: '500 Subscribers', quantity: 500, price: 899.0, isPopular: true },
          { id: 'chip_3', label: '1,000 Subscribers', quantity: 1000, price: 1699.0 },
        ],
      },
      elements: [
        {
          id: 'el_yt_head',
          key: 'heading_yt',
          label: 'Subscribe to YouTube Channel',
          category: 'display',
          type: ElementType.HEADING,
          visibility: VisibilityContext.BOTH,
          editability: EditabilityMode.ADMIN_FIXED,
        },
        {
          id: 'el_yt_url',
          key: 'channel_url',
          label: 'YouTube Channel Link / URL',
          category: 'input',
          type: ElementType.TEXT_FIELD,
          visibility: VisibilityContext.BOTH,
          editability: EditabilityMode.BUYER_INPUT,
          isRequired: true,
        },
        {
          id: 'el_yt_player',
          key: 'youtube_target_player',
          label: 'YouTube Target Channel Launcher',
          category: 'media',
          type: ElementType.YOUTUBE_PLAYER,
          visibility: VisibilityContext.WORKER_ONLY,
          editability: EditabilityMode.WORKER_READONLY,
        },
        {
          id: 'el_proof_scr',
          key: 'system_screenshot_proof',
          label: 'Screenshot Proof Verification',
          category: 'system',
          type: ElementType.SYSTEM_PROOF,
          visibility: VisibilityContext.WORKER_ONLY,
          editability: EditabilityMode.SYSTEM_CALCULATED,
          isRequired: true,
        },
      ],
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // 2. Instagram Followers Template
    this.templatesStore.set('srv_insta_followers', {
      id: 'srv_insta_followers',
      code: 'INSTAGRAM_FOLLOW',
      name: 'Instagram Profile Followers',
      description: 'Boost your Instagram profile reach and organic follower count.',
      isActive: true,
      pricing: {
        modelType: PricingModelType.COUNT_BASED,
        buyerPrice: 2.0,
        unitPrice: 2.0,
        minQuantity: 50,
        maxQuantity: 10000,
        adminMarginPercent: 20.0,
        workerReward: 1.6,
      },
      elements: [
        {
          id: 'el_insta_head',
          key: 'heading_insta',
          label: 'Instagram Profile Follow Task',
          category: 'display',
          type: ElementType.HEADING,
          visibility: VisibilityContext.BOTH,
          editability: EditabilityMode.ADMIN_FIXED,
        },
        {
          id: 'el_insta_handle',
          key: 'instagram_handle',
          label: 'Instagram Profile Link / Username',
          category: 'input',
          type: ElementType.TEXT_FIELD,
          visibility: VisibilityContext.BOTH,
          editability: EditabilityMode.BUYER_INPUT,
          isRequired: true,
        },
      ],
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }
}
