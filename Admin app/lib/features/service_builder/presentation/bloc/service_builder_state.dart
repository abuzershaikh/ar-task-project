import 'package:equatable/equatable.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/template_element.dart';

abstract class ServiceBuilderState extends Equatable {
  const ServiceBuilderState();

  @override
  List<Object?> get props => [];
}

class ServiceBuilderInitial extends ServiceBuilderState {}

class ServiceBuilderLoading extends ServiceBuilderState {}

class ServiceCatalogLoaded extends ServiceBuilderState {
  final List<ServiceModel> services;
  const ServiceCatalogLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

class ServiceEditingState extends ServiceBuilderState {
  final ServiceModel serviceDraft;
  final TemplateElement? selectedElement;
  final String? errorMessage;
  final bool isSaving;
  final bool isPublishing;
  final String? successMessage;

  const ServiceEditingState({
    required this.serviceDraft,
    this.selectedElement,
    this.errorMessage,
    this.isSaving = false,
    this.isPublishing = false,
    this.successMessage,
  });

  ServiceEditingState copyWith({
    ServiceModel? serviceDraft,
    TemplateElement? selectedElement,
    String? errorMessage,
    bool? isSaving,
    bool? isPublishing,
    String? successMessage,
  }) {
    return ServiceEditingState(
      serviceDraft: serviceDraft ?? this.serviceDraft,
      selectedElement: selectedElement ?? this.selectedElement,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
      isPublishing: isPublishing ?? this.isPublishing,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        serviceDraft,
        selectedElement,
        errorMessage,
        isSaving,
        isPublishing,
        successMessage,
      ];
}

class ServiceBuilderError extends ServiceBuilderState {
  final String message;
  const ServiceBuilderError(this.message);

  @override
  List<Object?> get props => [message];
}

class ServiceDeletedState extends ServiceBuilderState {
  final String message;
  const ServiceDeletedState(this.message);

  @override
  List<Object?> get props => [message];
}

