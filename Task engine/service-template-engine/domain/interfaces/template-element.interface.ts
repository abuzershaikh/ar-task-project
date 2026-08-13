import { VisibilityContext } from '../enums/visibility-context.enum';
import { EditabilityMode } from '../enums/editability-mode.enum';
import { ElementType } from '../enums/element-type.enum';

export interface ITemplateElement {
  id: string;
  key: string;
  label: string;
  category: 'display' | 'input' | 'media' | 'action' | 'system';
  type: ElementType;
  visibility: VisibilityContext;
  editability: EditabilityMode;
  isRequired?: boolean;
  defaultValue?: any;
  placeholder?: string;
  options?: string[];
  sortOrder?: number;
}
