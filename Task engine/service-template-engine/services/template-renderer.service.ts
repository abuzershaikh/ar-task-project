import { Injectable } from '@nestjs/common';
import { ITemplateElement } from '../domain/interfaces/template-element.interface';
import { VisibilityContext } from '../domain/enums/visibility-context.enum';

export interface IRenderedTemplateView {
  serviceId: string;
  serviceCode: string;
  name: string;
  description: string;
  targetRole: 'BUYER' | 'WORKER';
  elements: ITemplateElement[];
}

@Injectable()
export class TemplateRendererService {
  /**
   * Render template elements specifically for Buyer App
   * Filters elements where visibility == BUYER_ONLY or BOTH.
   */
  renderForBuyer(serviceTemplate: any): IRenderedTemplateView {
    const rawElements: ITemplateElement[] = serviceTemplate.elements || [];
    const buyerElements = rawElements.filter(
      (el) =>
        el.visibility === VisibilityContext.BUYER_ONLY ||
        el.visibility === VisibilityContext.BOTH
    );

    return {
      serviceId: serviceTemplate.id,
      serviceCode: serviceTemplate.code || serviceTemplate.serviceType,
      name: serviceTemplate.name || serviceTemplate.title,
      description: serviceTemplate.description || '',
      targetRole: 'BUYER',
      elements: buyerElements,
    };
  }

  /**
   * Render template elements specifically for Worker App
   * Filters elements where visibility == WORKER_ONLY or BOTH.
   */
  renderForWorker(serviceTemplate: any, buyerInputValues?: Record<string, any>): IRenderedTemplateView {
    const rawElements: ITemplateElement[] = serviceTemplate.elements || [];
    const workerElements = rawElements
      .filter(
        (el) =>
          el.visibility === VisibilityContext.WORKER_ONLY ||
          el.visibility === VisibilityContext.BOTH
      )
      .map((el) => {
        // Hydrate buyer input values into worker instructions
        const hydratedValue = buyerInputValues && buyerInputValues[el.key] !== undefined
          ? buyerInputValues[el.key]
          : el.defaultValue;

        return {
          ...el,
          defaultValue: hydratedValue,
        };
      });

    return {
      serviceId: serviceTemplate.id,
      serviceCode: serviceTemplate.code || serviceTemplate.serviceType,
      name: serviceTemplate.name || serviceTemplate.title,
      description: serviceTemplate.description || '',
      targetRole: 'WORKER',
      elements: workerElements,
    };
  }
}
