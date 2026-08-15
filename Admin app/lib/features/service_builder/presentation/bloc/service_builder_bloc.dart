import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_builder_repository.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/pricing_config.dart';
import '../../domain/models/template_element.dart';

import 'service_builder_event.dart';
import 'service_builder_state.dart';

class ServiceBuilderBloc extends Bloc<ServiceBuilderEvent, ServiceBuilderState> {
  final ServiceBuilderRepository repository;

  ServiceBuilderBloc({required this.repository}) : super(ServiceBuilderInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<SelectServiceForEditEvent>(_onSelectServiceForEdit);
    on<CreateNewServiceDraftEvent>(_onCreateNewServiceDraft);
    on<UpdatePricingEvent>(_onUpdatePricing);
    on<AddPriceChipEvent>(_onAddPriceChip);
    on<RemovePriceChipEvent>(_onRemovePriceChip);
    on<UpdatePriceChipEvent>(_onUpdatePriceChip);
    on<AddTemplateElementEvent>(_onAddTemplateElement);
    on<RemoveTemplateElementEvent>(_onRemoveTemplateElement);
    on<ReorderTemplateElementsEvent>(_onReorderTemplateElements);
    on<UpdateElementPropertiesEvent>(_onUpdateElementProperties);
    on<SaveServiceDraftEvent>(_onSaveServiceDraft);
    on<PublishServiceVersionEvent>(_onPublishServiceVersion);
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
    final newService = ServiceModel(
      id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
      code: cleanCode,
      name: event.name,
      description: 'Custom Service created by Admin',
      isActive: true,
      currentVersion: 1,
      pricing: PricingConfig.calculate(
        modelType: PricingModelType.tieredChips,
        buyerPrice: 199.0,
        adminMarginPercent: 20.0,
        chips: const [
          PriceChipModel(id: 'chip_1', label: '100 Count (Basic)', quantity: 100, price: 199.0),
          PriceChipModel(id: 'chip_2', label: '500 Count (Standard)', quantity: 500, price: 899.0, isPopular: true),
          PriceChipModel(id: 'chip_3', label: '1000 Count (Pro Pack)', quantity: 1000, price: 1699.0),
        ],
      ),
      elements: [],
      updatedAt: DateTime.now(),
    );
    emit(ServiceEditingState(serviceDraft: newService));
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
        chips: event.chips ?? currentP.chips,
      );

      final updatedService = currentState.serviceDraft.copyWith(pricing: newPricing);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        errorMessage: newPricing.validationError,
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
      emit(currentState.copyWith(serviceDraft: updatedService));
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
      emit(currentState.copyWith(serviceDraft: updatedService));
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
      emit(currentState.copyWith(serviceDraft: updatedService));
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
      emit(currentState.copyWith(serviceDraft: updatedService));
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

      final updatedService = currentState.serviceDraft.copyWith(elements: currentElements);
      emit(currentState.copyWith(
        serviceDraft: updatedService,
        selectedElement: event.updatedElement,
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
        final published = await repository.publishServiceVersion(event.serviceId);
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
}
