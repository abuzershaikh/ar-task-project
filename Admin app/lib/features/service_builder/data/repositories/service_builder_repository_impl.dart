import 'package:dio/dio.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/pricing_config.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/element_category.dart';
import '../../domain/models/element_type.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';
import '../../domain/models/action_type.dart';
import '../../domain/repositories/service_builder_repository.dart';

class ServiceBuilderRepositoryImpl implements ServiceBuilderRepository {
  final Dio? dio;

  // In-memory store for instant UI editing & versioning
  final List<ServiceModel> _mockServices = [
    ServiceModel(
      id: 'srv_yt_sub_01',
      code: 'YT_SUB',
      name: 'YouTube Channel Subscriber',
      description: 'Gain real subscribers for your YouTube channel with proof verification.',
      icon: 'subscriptions_rounded',
      isActive: true,
      currentVersion: 1,
      pricing: PricingConfig.calculate(buyerPrice: 50.0, adminMarginPercent: 20.0),
      elements: [
        const TemplateElement(
          id: 'el_01',
          key: 'header_banner',
          label: 'Subscribe to YouTube Channel',
          category: ElementCategory.content,
          type: ElementType.heading,
          visibility: VisibilityContext.both,
          editability: EditabilityMode.adminFixed,
          isRequired: true,
          orderIndex: 0,
        ),
        const TemplateElement(
          id: 'el_02',
          key: 'youtube_url',
          label: 'YouTube Channel / Video Link',
          category: ElementCategory.input,
          type: ElementType.textField,
          visibility: VisibilityContext.both,
          editability: EditabilityMode.buyerInput,
          isRequired: true,
          properties: {'placeholder': 'https://youtube.com/@channel'},
          orderIndex: 1,
        ),
        const TemplateElement(
          id: 'el_03',
          key: 'subscribe_btn',
          label: 'Subscribe Now',
          category: ElementCategory.interactive,
          type: ElementType.actionButton,
          visibility: VisibilityContext.workerOnly,
          editability: EditabilityMode.workerInteractive,
          isRequired: true,
          actionType: ActionType.subscribeChannel,
          orderIndex: 2,
        ),
        const TemplateElement(
          id: 'el_04',
          key: 'system_proof',
          label: 'Submit Screenshot Proof',
          category: ElementCategory.system,
          type: ElementType.systemProof,
          visibility: VisibilityContext.workerOnly,
          editability: EditabilityMode.workerInteractive,
          isRequired: true,
          orderIndex: 3,
        ),
      ],
      updatedAt: DateTime.now(),
    ),
    ServiceModel(
      id: 'srv_tg_join_02',
      code: 'TELEGRAM_JOIN',
      name: 'Telegram Group / Channel Join',
      description: 'Get targeted members to join your Telegram group or channel.',
      icon: 'telegram_rounded',
      isActive: true,
      currentVersion: 2,
      pricing: PricingConfig.calculate(buyerPrice: 30.0, adminMarginPercent: 15.0),
      elements: [
        const TemplateElement(
          id: 'el_10',
          key: 'tg_header',
          label: 'Join Telegram Channel',
          category: ElementCategory.content,
          type: ElementType.heading,
          visibility: VisibilityContext.both,
          editability: EditabilityMode.adminFixed,
          orderIndex: 0,
        ),
        const TemplateElement(
          id: 'el_11',
          key: 'telegram_link',
          label: 'Telegram Invite Link',
          category: ElementCategory.input,
          type: ElementType.textField,
          visibility: VisibilityContext.both,
          editability: EditabilityMode.buyerInput,
          isRequired: true,
          properties: {'placeholder': 'https://t.me/yourchannel'},
          orderIndex: 1,
        ),
        const TemplateElement(
          id: 'el_12',
          key: 'join_btn',
          label: 'Open Telegram Link',
          category: ElementCategory.interactive,
          type: ElementType.actionButton,
          visibility: VisibilityContext.workerOnly,
          editability: EditabilityMode.workerInteractive,
          actionType: ActionType.openUrl,
          orderIndex: 2,
        ),
        const TemplateElement(
          id: 'el_13',
          key: 'system_proof',
          label: 'Screenshot Proof',
          category: ElementCategory.system,
          type: ElementType.systemProof,
          visibility: VisibilityContext.workerOnly,
          editability: EditabilityMode.workerInteractive,
          orderIndex: 3,
        ),
      ],
      updatedAt: DateTime.now(),
    ),
  ];

  ServiceBuilderRepositoryImpl({this.dio});

  @override
  Future<List<ServiceModel>> getServices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockServices);
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockServices.firstWhere(
      (s) => s.id == id,
      orElse: () => _mockServices.first,
    );
  }

  @override
  Future<ServiceModel> saveServiceDraft(ServiceModel service) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockServices.indexWhere((s) => s.id == service.id);
    if (index >= 0) {
      _mockServices[index] = service;
    } else {
      _mockServices.add(service);
    }
    return service;
  }

  @override
  Future<ServiceModel> publishServiceVersion(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockServices.indexWhere((s) => s.id == serviceId);
    if (index >= 0) {
      final existing = _mockServices[index];
      final published = existing.copyWith(
        currentVersion: existing.currentVersion + 1,
        updatedAt: DateTime.now(),
      );
      _mockServices[index] = published;
      return published;
    }
    throw Exception('Service not found for publishing');
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockServices.removeWhere((s) => s.id == serviceId);
  }
}
