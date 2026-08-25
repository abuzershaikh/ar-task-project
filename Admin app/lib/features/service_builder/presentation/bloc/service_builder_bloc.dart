import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_builder_repository.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/pricing_config.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/element_category.dart';
import '../../domain/models/element_type.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';

import 'service_builder_event.dart';
import 'service_builder_state.dart';

class ServiceBuilderBloc extends Bloc<ServiceBuilderEvent, ServiceBuilderState> {
  final ServiceBuilderRepository repository;

  ServiceBuilderBloc({required this.repository}) : super(ServiceBuilderInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<SelectServiceForEditEvent>(_onSelectServiceForEdit);
    on<CreateNewServiceDraftEvent>(_onCreateNewServiceDraft);
    on<UpdateServiceInfoEvent>(_onUpdateServiceInfo);
    on<UpdatePricingEvent>(_onUpdatePricing);
    on<AddPriceChipEvent>(_onAddPriceChip);
    on<RemovePriceChipEvent>(_onRemovePriceChip);
    on<UpdatePriceChipEvent>(_onUpdatePriceChip);
    on<AddTemplateElementEvent>(_onAddTemplateElement);
    on<RemoveTemplateElementEvent>(_onRemoveTemplateElement);
    on<ReorderTemplateElementsEvent>(_onReorderTemplateElements);
    on<SaveServiceDraftEvent>(_onSaveServiceDraft);
    on<UpdateTimingRulesEvent>(_onUpdateTimingRules);
    on<PublishServiceVersionEvent>(_onPublishServiceVersion);
    on<DeleteServiceEvent>(_onDeleteService);
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<ServiceBuilderState> emit,
  ) async {
    emit(ServiceBuilderLoading());
    try {
      final services = await repository.getServices();
      emit(ServiceCatalogLoaded(services));
    } catch (e) {
      emit(ServiceBuilderError('Failed to load services: $e'));
    }
  }

  Future<void> _onSelectServiceForEdit(
    SelectServiceForEditEvent event,
    Emitter<ServiceBuilderState> emit,
  ) async {
    emit(ServiceBuilderLoading());
    try {
      final service = await repository.getServiceById(event.serviceId);
      emit(ServiceEditingState(serviceDraft: service));
    } catch (e) {
      emit(ServiceBuilderError('Failed to load service details: $e'));
    }
  }

  void _onCreateNewServiceDraft(
    CreateNewServiceDraftEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    final cleanCode = event.code.toUpperCase().replaceAll(' ', '_');
    final defaultElements = <TemplateElement>[
      TemplateElement(
        id: 'el_header',
        key: 'header_title',
        label: event.name.isNotEmpty ? event.name : 'Campaign Header / Title',
        category: ElementCategory.content,
        type: ElementType.heading,
        visibility: VisibilityContext.both,
        editability: EditabilityMode.adminFixed,
        isRequired: true,
        orderIndex: 0,
        properties: {'content': event.name},
      ),
      TemplateElement(
        id: 'el_instructions',
        key: 'gig_worker_instructions',
        label: 'Task Details & Instructions for Workers',
        category: ElementCategory.content,
        type: ElementType.paragraph,
        visibility: VisibilityContext.both,
        editability: EditabilityMode.adminFixed,
        isRequired: true,
        orderIndex: 1,
        properties: {'content': event.description ?? 'Complete the task as instructed by admin.'},
      ),
      TemplateElement(
        id: 'el_count_quantity',
        key: 'buyer_order_quantity',
        label: 'Order Count / Quantity Required',
        category: ElementCategory.input,
        type: ElementType.numberField,
        visibility: VisibilityContext.buyerOnly,
        editability: EditabilityMode.buyerInput,
        isRequired: true,
        orderIndex: 2,
        properties: {'placeholder': 'Enter required quantity (e.g. 100, 500, 1000)', 'min': 10, 'max': 100000},
      ),
      TemplateElement(
        id: 'el_target_url',
        key: 'target_url',
        label: 'Target Action Link (Channel / Post / Video URL)',
        category: ElementCategory.interactive,
        type: ElementType.actionButton,
        visibility: VisibilityContext.both,
        editability: EditabilityMode.buyerInput,
        isRequired: true,
        orderIndex: 3,
        properties: {
          'buttonText': 'Open Link & Complete Task',
          'placeholder': 'https://youtube.com/watch?v=... or https://t.me/...',
        },
      ),
      TemplateElement(
        id: 'el_yt_video',
        key: 'yt_video_preview',
        label: 'YouTube Video Link (Admin Tutorial)',
        category: ElementCategory.media,
        type: ElementType.youtube,
        visibility: VisibilityContext.both,
        editability: EditabilityMode.adminFixed,
        isRequired: false,
        orderIndex: 4,
        properties: {'url': ''},
      ),
      TemplateElement(
        id: 'el_voice_rec',
        key: 'voice_instruction',
        label: 'Voice Guide / Audio Recording (Admin)',
        category: ElementCategory.media,
        type: ElementType.audio,
        visibility: VisibilityContext.both,
        editability: EditabilityMode.adminFixed,
        isRequired: false,
        orderIndex: 5,
        properties: {'url': ''},
      ),
      TemplateElement(
        id: 'el_proof_submit',
        key: 'system_proof_requirements',
        label: 'Proof Requirements & Verification',
        category: ElementCategory.system,
        type: ElementType.systemProof,
        visibility: VisibilityContext.both,
        editability: EditabilityMode.adminFixed,
        isRequired: true,
        orderIndex: 6,
        properties: {
          'requireScreenshot': true,
          'requireTextProof': false,
        },
      ),
      TemplateElement(
        id: 'el_task_timer',
        key: 'system_task_timer',
        label: 'Required Task Duration Timer',
        category: ElementCategory.system,
        type: ElementType.systemTimer,
        visibility: VisibilityContext.workerOnly,
        editability: EditabilityMode.adminFixed,
        isRequired: true,
        orderIndex: 7,
        properties: {
          'durationSeconds': 60,
        },
      ),
    ];

    final basePrice = event.buyerUnitPrice ?? 0.0;
    final marginPercent = event.adminMarginPercent ?? 0.0;

    final newService = ServiceModel(
      id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
      code: cleanCode,
      name: event.name,
      description: event.description?.isNotEmpty == true
          ? event.description!
          : 'Service created and managed by Admin',
      isActive: true,
      currentVersion: 1,
      pricing: PricingConfig.calculate(
        modelType: PricingModelType.countBased,
        buyerPrice: basePrice,
        unitPrice: basePrice > 0 ? basePrice : 1.0,
        adminMarginPercent: marginPercent,
        chips: basePrice > 0
            ? [
                PriceChipModel(id: 'chip_1', label: '100 Count', quantity: 100, price: basePrice * 100),
                PriceChipModel(id: 'chip_2', label: '500 Count', quantity: 500, price: basePrice * 500, isPopular: true),
                PriceChipModel(id: 'chip_3', label: '1000 Count', quantity: 1000, price: basePrice * 1000),
              ]
            : [],
      ),
      elements: defaultElements,
      updatedAt: DateTime.now(),
    );
    emit(ServiceEditingState(serviceDraft: newService));
  }

  void _onUpdateServiceInfo(
    UpdateServiceInfoEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;

      final updatedElements = currentState.serviceDraft.elements.map((el) {
        if (el.id == 'el_header' || el.key == 'header_title' || el.type == ElementType.heading) {
          return el.copyWith(
            label: event.name,
            properties: {...el.properties, 'content': event.name},
          );
        }
        if (el.id == 'el_instructions' || el.key == 'gig_worker_instructions' || el.type == ElementType.paragraph) {
          if (event.description != null && event.description!.isNotEmpty) {
            return el.copyWith(
              properties: {...el.properties, 'content': event.description},
            );
          }
        }
        return el;
      }).toList();

      final updatedDraft = currentState.serviceDraft.copyWith(
        name: event.name,
        description: event.description,
        elements: updatedElements,
        videoTutorialUrl: event.videoTutorialUrl,
        audioGuideUrl: event.audioGuideUrl,
        adminInstructions: event.adminInstructions,
        linkFieldLabel: event.linkFieldLabel,
        linkFieldPlaceholder: event.linkFieldPlaceholder,
        textFieldLabel: event.textFieldLabel,
        textFieldPlaceholder: event.textFieldPlaceholder,
        watchtimeSeconds: event.watchtimeSeconds,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(
        serviceDraft: updatedDraft,
        successMessage: 'Service basic info & guidance updated!',
      ));
    }
  }

  void _onUpdateTimingRules(
    UpdateTimingRulesEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final updatedDraft = currentState.serviceDraft.copyWith(
        minCompleteHours: event.minCompleteHours ?? currentState.serviceDraft.minCompleteHours,
        maxCompleteHours: event.maxCompleteHours ?? currentState.serviceDraft.maxCompleteHours,
        minAcceptHours: event.minAcceptHours ?? currentState.serviceDraft.minAcceptHours,
        maxAcceptHours: event.maxAcceptHours ?? currentState.serviceDraft.maxAcceptHours,
        minDurationSeconds: event.minDurationSeconds ?? currentState.serviceDraft.minDurationSeconds,
        maxDurationSeconds: event.maxDurationSeconds ?? currentState.serviceDraft.maxDurationSeconds,
        updatedAt: DateTime.now(),
      );
      emit(currentState.copyWith(
        serviceDraft: updatedDraft,
        successMessage: 'Execution timing rules updated!',
      ));
    }
  }

  void _onUpdatePricing(
    UpdatePricingEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentP = currentState.serviceDraft.pricing;

      final newPricing = PricingConfig.calculate(
        modelType: event.modelType ?? currentP.modelType,
        buyerPrice: event.buyerPrice ?? currentP.buyerPrice,
        unitPrice: event.unitPrice ?? currentP.unitPrice,
        minQuantity: event.minQuantity ?? currentP.minQuantity,
        maxQuantity: event.maxQuantity ?? currentP.maxQuantity,
        adminMarginPercent: event.adminMarginPercent ?? currentP.adminMarginPercent,
        workerReward: event.workerReward ?? currentP.workerReward,
        chips: event.chips ?? currentP.chips,
      );

      final updatedService = currentState.serviceDraft.copyWith(
        pricing: newPricing,
        workerLimit: event.workerLimit ?? currentState.serviceDraft.workerLimit,
        workerLimitOptions: event.workerLimitOptions ?? currentState.serviceDraft.workerLimitOptions,
      );
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        errorMessage: newPricing.validationError,
        successMessage: newPricing.isValid ? 'Pricing configuration updated!' : null,
      ));
    }
  }

  void _onAddPriceChip(
    AddPriceChipEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentP = currentState.serviceDraft.pricing;
      final updatedChips = List<PriceChipModel>.from(currentP.chips)..add(event.chip);

      final newPricing = PricingConfig.calculate(
        modelType: currentP.modelType,
        buyerPrice: currentP.buyerPrice,
        unitPrice: currentP.unitPrice,
        minQuantity: currentP.minQuantity,
        maxQuantity: currentP.maxQuantity,
        adminMarginPercent: currentP.adminMarginPercent,
        chips: updatedChips,
      );

      final updatedService = currentState.serviceDraft.copyWith(pricing: newPricing);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        successMessage: 'Price chip added!',
      ));
    }
  }

  void _onRemovePriceChip(
    RemovePriceChipEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentP = currentState.serviceDraft.pricing;
      final updatedChips = List<PriceChipModel>.from(currentP.chips)..removeWhere((c) => c.id == event.chipId);

      final newPricing = PricingConfig.calculate(
        modelType: currentP.modelType,
        buyerPrice: currentP.buyerPrice,
        unitPrice: currentP.unitPrice,
        minQuantity: currentP.minQuantity,
        maxQuantity: currentP.maxQuantity,
        adminMarginPercent: currentP.adminMarginPercent,
        chips: updatedChips,
      );

      final updatedService = currentState.serviceDraft.copyWith(pricing: newPricing);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        successMessage: 'Price chip removed!',
      ));
    }
  }

  void _onUpdatePriceChip(
    UpdatePriceChipEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentP = currentState.serviceDraft.pricing;
      final updatedChips = List<PriceChipModel>.from(currentP.chips);

      final idx = updatedChips.indexWhere((c) => c.id == event.chip.id);
      if (idx >= 0) {
        updatedChips[idx] = event.chip;
      }

      final newPricing = PricingConfig.calculate(
        modelType: currentP.modelType,
        buyerPrice: currentP.buyerPrice,
        unitPrice: currentP.unitPrice,
        minQuantity: currentP.minQuantity,
        maxQuantity: currentP.maxQuantity,
        adminMarginPercent: currentP.adminMarginPercent,
        chips: updatedChips,
      );

      final updatedService = currentState.serviceDraft.copyWith(pricing: newPricing);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        successMessage: 'Price chip updated!',
      ));
    }
  }

  void _onAddTemplateElement(
    AddTemplateElementEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentElements = List<TemplateElement>.from(currentState.serviceDraft.elements);
      
      final indexedElement = event.element.copyWith(
        orderIndex: currentElements.length,
      );
      currentElements.add(indexedElement);

      final updatedService = currentState.serviceDraft.copyWith(elements: currentElements);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        selectedElement: indexedElement,
        successMessage: 'Added "${event.element.label}" component!',
      ));
    }
  }

  void _onRemoveTemplateElement(
    RemoveTemplateElementEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentElements = List<TemplateElement>.from(currentState.serviceDraft.elements);
      
      currentElements.removeWhere((e) => e.id == event.elementId);
      for (int i = 0; i < currentElements.length; i++) {
        currentElements[i] = currentElements[i].copyWith(orderIndex: i);
      }

      final updatedService = currentState.serviceDraft.copyWith(elements: currentElements);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        selectedElement: null,
        successMessage: 'Component removed!',
      ));
    }
  }

  void _onReorderTemplateElements(
    ReorderTemplateElementsEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentElements = List<TemplateElement>.from(currentState.serviceDraft.elements);
      
      int newIdx = event.newIndex;
      if (newIdx > event.oldIndex) newIdx -= 1;
      
      final moved = currentElements.removeAt(event.oldIndex);
      currentElements.insert(newIdx, moved);

      for (int i = 0; i < currentElements.length; i++) {
        currentElements[i] = currentElements[i].copyWith(orderIndex: i);
      }

      final updatedService = currentState.serviceDraft.copyWith(elements: currentElements);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        successMessage: 'Components reordered!',
      ));
    }
  }

  void _onUpdateElementProperties(
    UpdateElementPropertiesEvent event,
    Emitter<ServiceBuilderState> emit,
  ) {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      final currentElements = List<TemplateElement>.from(currentState.serviceDraft.elements);
      
      final idx = currentElements.indexWhere((e) => e.id == event.updatedElement.id);
      if (idx >= 0) {
        currentElements[idx] = event.updatedElement;
      }

      // If the updated element is heading, keep serviceDraft.name in sync!
      String newName = currentState.serviceDraft.name;
      if (event.updatedElement.type == ElementType.heading ||
          event.updatedElement.id == 'el_header' ||
          event.updatedElement.key == 'header_title') {
        if (event.updatedElement.label.isNotEmpty) {
          newName = event.updatedElement.label;
        }
      }

      final updatedService = currentState.serviceDraft.copyWith(
        name: newName,
        elements: currentElements,
      );
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        selectedElement: event.updatedElement,
        successMessage: 'Saved "${event.updatedElement.label}" settings!',
      ));
    }
  }

  Future<void> _onSaveServiceDraft(
    SaveServiceDraftEvent event,
    Emitter<ServiceBuilderState> emit,
  ) async {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      emit(currentState.copyWith(isSaving: true));
      try {
        final saved = await repository.saveServiceDraft(currentState.serviceDraft);
        emit(currentState.copyWith(
          serviceDraft: saved,
          isSaving: false,
          successMessage: 'Draft saved successfully!',
        ));
      } catch (e) {
        emit(currentState.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save draft: $e',
        ));
      }
    }
  }

  Future<void> _onPublishServiceVersion(
    PublishServiceVersionEvent event,
    Emitter<ServiceBuilderState> emit,
  ) async {
    if (state is ServiceEditingState) {
      final currentState = state as ServiceEditingState;
      
      if (!currentState.serviceDraft.pricing.isValid) {
        emit(currentState.copyWith(
          errorMessage: 'Cannot publish! ${currentState.serviceDraft.pricing.validationError}',
        ));
        return;
      }

      emit(currentState.copyWith(isPublishing: true));
      try {
        final draftToPublish = currentState.serviceDraft.copyWith(
          isActive: true,
          currentVersion: currentState.serviceDraft.currentVersion + 1,
          updatedAt: DateTime.now(),
        );
        final published = await repository.saveServiceDraft(draftToPublish);
        emit(currentState.copyWith(
          serviceDraft: published,
          isPublishing: false,
          successMessage: 'Published Version V${published.currentVersion} successfully!',
        ));
      } catch (e) {
        emit(currentState.copyWith(
          isPublishing: false,
          errorMessage: 'Publishing failed: $e',
        ));
      }
    }
  }

  Future<void> _onDeleteService(
    DeleteServiceEvent event,
    Emitter<ServiceBuilderState> emit,
  ) async {
    emit(ServiceBuilderLoading());
    try {
      await repository.deleteService(event.serviceId);
      emit(const ServiceDeletedState('Service deleted successfully!'));
    } catch (e) {
      emit(ServiceBuilderError('Failed to delete service: $e'));
    }
  }
}

