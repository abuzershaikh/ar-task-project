import 'package:equatable/equatable.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/pricing_config.dart';

abstract class ServiceBuilderEvent extends Equatable {
  const ServiceBuilderEvent();

  @override
  List<Object?> get props => [];
}

class LoadServicesEvent extends ServiceBuilderEvent {}

class SelectServiceForEditEvent extends ServiceBuilderEvent {
  final String serviceId;
  const SelectServiceForEditEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class CreateNewServiceDraftEvent extends ServiceBuilderEvent {
  final String code;
  final String name;
  final String? description;
  final double? buyerUnitPrice;
  final double? adminMarginPercent;

  const CreateNewServiceDraftEvent({
    required this.code,
    required this.name,
    this.description,
    this.buyerUnitPrice,
    this.adminMarginPercent,
  });

  @override
  List<Object?> get props => [code, name, description, buyerUnitPrice, adminMarginPercent];
}

class UpdateServiceInfoEvent extends ServiceBuilderEvent {
  final String name;
  final String description;
  final String? videoTutorialUrl;
  final String? audioGuideUrl;
  final String? adminInstructions;
  final String? linkFieldLabel;
  final String? linkFieldPlaceholder;
  final String? textFieldLabel;
  final String? textFieldPlaceholder;
  final int? watchtimeSeconds;

  const UpdateServiceInfoEvent({
    required this.name,
    required this.description,
    this.videoTutorialUrl,
    this.audioGuideUrl,
    this.adminInstructions,
    this.linkFieldLabel,
    this.linkFieldPlaceholder,
    this.textFieldLabel,
    this.textFieldPlaceholder,
    this.watchtimeSeconds,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        videoTutorialUrl,
        audioGuideUrl,
        adminInstructions,
        linkFieldLabel,
        linkFieldPlaceholder,
        textFieldLabel,
        textFieldPlaceholder,
        watchtimeSeconds,
      ];
}

class UpdatePricingEvent extends ServiceBuilderEvent {
  final PricingModelType? modelType;
  final double? buyerPrice;
  final double? unitPrice;
  final int? minQuantity;
  final int? maxQuantity;
  final double? adminMarginPercent;
  final double? workerReward;
  final int? workerLimit;
  final List<int>? workerLimitOptions;
  final List<PriceChipModel>? chips;

  const UpdatePricingEvent({
    this.modelType,
    this.buyerPrice,
    this.unitPrice,
    this.minQuantity,
    this.maxQuantity,
    this.adminMarginPercent,
    this.workerReward,
    this.workerLimit,
    this.workerLimitOptions,
    this.chips,
  });

  @override
  List<Object?> get props => [
        modelType,
        buyerPrice,
        unitPrice,
        minQuantity,
        maxQuantity,
        adminMarginPercent,
        workerReward,
        workerLimit,
        workerLimitOptions,
        chips,
      ];
}

class AddPriceChipEvent extends ServiceBuilderEvent {
  final PriceChipModel chip;
  const AddPriceChipEvent(this.chip);

  @override
  List<Object?> get props => [chip];
}

class RemovePriceChipEvent extends ServiceBuilderEvent {
  final String chipId;
  const RemovePriceChipEvent(this.chipId);

  @override
  List<Object?> get props => [chipId];
}

class UpdatePriceChipEvent extends ServiceBuilderEvent {
  final PriceChipModel chip;
  const UpdatePriceChipEvent(this.chip);

  @override
  List<Object?> get props => [chip];
}

class AddTemplateElementEvent extends ServiceBuilderEvent {
  final TemplateElement element;
  const AddTemplateElementEvent(this.element);

  @override
  List<Object?> get props => [element];
}

class RemoveTemplateElementEvent extends ServiceBuilderEvent {
  final String elementId;
  const RemoveTemplateElementEvent(this.elementId);

  @override
  List<Object?> get props => [elementId];
}

class ReorderTemplateElementsEvent extends ServiceBuilderEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderTemplateElementsEvent(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class UpdateElementPropertiesEvent extends ServiceBuilderEvent {
  final TemplateElement updatedElement;
  const UpdateElementPropertiesEvent(this.updatedElement);

  @override
  List<Object?> get props => [updatedElement];
}

class UpdateTimingRulesEvent extends ServiceBuilderEvent {
  final int? minCompleteHours;
  final int? maxCompleteHours;
  final int? minAcceptHours;
  final int? maxAcceptHours;
  final int? minDurationSeconds;
  final int? maxDurationSeconds;

  const UpdateTimingRulesEvent({
    this.minCompleteHours,
    this.maxCompleteHours,
    this.minAcceptHours,
    this.maxAcceptHours,
    this.minDurationSeconds,
    this.maxDurationSeconds,
  });

  @override
  List<Object?> get props => [
        minCompleteHours,
        maxCompleteHours,
        minAcceptHours,
        maxAcceptHours,
        minDurationSeconds,
        maxDurationSeconds,
      ];
}

class SaveServiceDraftEvent extends ServiceBuilderEvent {}

class PublishServiceVersionEvent extends ServiceBuilderEvent {
  final String serviceId;
  const PublishServiceVersionEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

class DeleteServiceEvent extends ServiceBuilderEvent {
  final String serviceId;
  const DeleteServiceEvent(this.serviceId);

  @override
  List<Object?> get props => [serviceId];
}

