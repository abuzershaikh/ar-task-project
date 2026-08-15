import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';
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
  final DioClient? dioClient;

  final List<ServiceModel> _mockServices = [];

  ServiceBuilderRepositoryImpl({this.dioClient});

  @override
  Future<List<ServiceModel>> getServices() async {
    if (dioClient != null) {
      try {
        final response = await dioClient!.get('/admin/services');
        if (response.statusCode == 200 && response.data != null) {
          final List<dynamic> list = response.data['services'] ?? response.data['data'] ?? [];
          final remoteServices = list.map((item) {
            final Map<String, dynamic> s = Map<String, dynamic>.from(item['service'] ?? item);
            final Map<String, dynamic>? pricingMap = item['activePricing'] != null
                ? Map<String, dynamic>.from(item['activePricing'])
                : (s['pricing'] != null ? Map<String, dynamic>.from(s['pricing']) : null);

            final double buyerPrice = pricingMap != null
                ? ((pricingMap['buyerUnitPrice'] ?? pricingMap['buyerPrice'] as num?) ?? 50.0).toDouble()
                : 50.0;
            final double marginVal = pricingMap != null
                ? ((pricingMap['marginValue'] ?? pricingMap['adminMarginPercent'] as num?) ?? 20.0).toDouble()
                : 20.0;
            final String marginType = pricingMap?['marginType']?.toString() ?? 'PERCENTAGE';

            List<TemplateElement> parsedElements = [];
            if (s['elements'] != null && s['elements'] is List) {
              try {
                parsedElements = (s['elements'] as List)
                    .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e as Map)))
                    .toList();
              } catch (_) {}
            }

            return ServiceModel(
              id: (s['id'] ?? '').toString(),
              code: (s['code'] ?? s['id'] ?? 'CUSTOM_SRV').toString().toUpperCase(),
              name: (s['name'] ?? s['title'] ?? 'Custom Service').toString(),
              description: (s['description'] ?? '').toString(),
              icon: 'settings_suggest_rounded',
              isActive: s['isActive'] ?? s['isPublished'] ?? true,
              currentVersion: (s['version'] as num?)?.toInt() ?? 1,
              pricing: PricingConfig.calculate(
                buyerPrice: buyerPrice,
                adminMarginPercent: marginVal,
                marginType: marginType,
              ),
              elements: parsedElements,
              reviewMode: (s['reviewMode'] ?? 'MANUAL').toString().toUpperCase(),
              updatedAt: s['updatedAt'] != null ? DateTime.tryParse(s['updatedAt']) ?? DateTime.now() : DateTime.now(),
            );
          }).toList();

          if (remoteServices.isNotEmpty) {
            return remoteServices;
          }
        }
      } catch (e) {
        debugPrint('[ADMIN REPO] Remote services fetch exception: $e');
      }
    }
    return List.from(_mockServices);
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    if (dioClient != null) {
      try {
        final response = await dioClient!.get('/admin/services/$id');
        if (response.statusCode == 200 && response.data != null) {
          final s = Map<String, dynamic>.from(response.data['service'] ?? response.data);
          final Map<String, dynamic>? pricingMap = response.data['activePricing'] != null
              ? Map<String, dynamic>.from(response.data['activePricing'])
              : null;

          final double buyerPrice = pricingMap != null
              ? ((pricingMap['buyerUnitPrice'] as num?) ?? 50.0).toDouble()
              : 50.0;
          final double marginVal = pricingMap != null
              ? ((pricingMap['marginValue'] as num?) ?? 20.0).toDouble()
              : 20.0;
          final String marginType = pricingMap?['marginType']?.toString() ?? 'PERCENTAGE';

          List<TemplateElement> parsedElements = [];
          if (s['elements'] != null && s['elements'] is List) {
            try {
              parsedElements = (s['elements'] as List)
                  .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList();
            } catch (_) {}
          }

          return ServiceModel(
            id: (s['id'] ?? id).toString(),
            code: (s['code'] ?? s['id'] ?? id).toString().toUpperCase(),
            name: (s['name'] ?? s['title'] ?? 'Custom Service').toString(),
            description: (s['description'] ?? '').toString(),
            icon: 'settings_suggest_rounded',
            isActive: s['isActive'] ?? s['isPublished'] ?? true,
            currentVersion: (s['version'] as num?)?.toInt() ?? 1,
            pricing: PricingConfig.calculate(
              buyerPrice: buyerPrice,
              adminMarginPercent: marginVal,
              marginType: marginType,
            ),
            elements: parsedElements,
            reviewMode: (s['reviewMode'] ?? 'MANUAL').toString().toUpperCase(),
            updatedAt: s['updatedAt'] != null ? DateTime.tryParse(s['updatedAt']) ?? DateTime.now() : DateTime.now(),
          );
        }
      } catch (e) {
        debugPrint('[ADMIN REPO] Remote getServiceById exception: $e');
      }
    }

    return _mockServices.firstWhere(
      (s) => s.id == id,
      orElse: () => _mockServices.first,
    );
  }

  @override
  Future<ServiceModel> saveServiceDraft(ServiceModel service) async {
    if (dioClient != null) {
      try {
        final elementsJson = service.elements.map((e) => e.toJson()).toList();

        final payload = {
          'code': service.code.isNotEmpty ? service.code : 'SRV_${DateTime.now().millisecondsSinceEpoch}',
          'name': service.name,
          'description': service.description,
          'buyerUnitPrice': service.pricing.buyerPrice,
          'marginType': service.pricing.marginType,
          'marginValue': service.pricing.adminMarginPercent,
          'elements': elementsJson,
          'reviewMode': service.reviewMode,
          'isActive': service.isActive,
        };

        if (service.id.isNotEmpty && !service.id.startsWith('mock_')) {
          await dioClient!.patch('/admin/services/${service.id}', data: {
            'name': service.name,
            'description': service.description,
            'isActive': service.isActive,
            'elements': elementsJson,
            'reviewMode': service.reviewMode,
          });
          await dioClient!.post('/admin/services/${service.id}/pricing', data: {
            'buyerUnitPrice': service.pricing.buyerPrice,
            'marginType': service.pricing.marginType,
            'marginValue': service.pricing.adminMarginPercent,
          });
        } else {
          final response = await dioClient!.post('/admin/services', data: payload);
          debugPrint('[ADMIN REPO] Remote saveServiceDraft response: ${response.data}');
        }
      } catch (e) {
        debugPrint('[ADMIN REPO] Remote saveServiceDraft exception: $e');
      }
    }

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
    final index = _mockServices.indexWhere((s) => s.id == serviceId);
    if (index >= 0) {
      final existing = _mockServices[index];
      final published = existing.copyWith(
        currentVersion: existing.currentVersion + 1,
        updatedAt: DateTime.now(),
      );
      _mockServices[index] = published;
      await saveServiceDraft(published);
      return published;
    }
    throw Exception('Service not found for publishing');
  }

  @override
  Future<void> deleteService(String serviceId) async {
    _mockServices.removeWhere((s) => s.id == serviceId);
  }
}
