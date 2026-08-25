import 'dart:convert';
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
  double _toDouble(dynamic val, double defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  int _toInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  List<int> _parseIntList(dynamic val, List<int> defaultValue) {
    if (val == null) return defaultValue;
    if (val is List) {
      final parsed = val.map((e) => _toInt(e, 0)).where((e) => e > 0).toList();
      return parsed.isNotEmpty ? parsed : defaultValue;
    }
    return defaultValue;
  }

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
                ? _toDouble(pricingMap['buyerUnitPrice'] ?? pricingMap['buyerPrice'], 0.0)
                : 0.0;
            final double marginVal = pricingMap != null
                ? _toDouble(pricingMap['marginValue'] ?? pricingMap['adminMarginPercent'], 0.0)
                : 0.0;
            final String marginType = pricingMap?['marginType']?.toString() ?? 'PERCENTAGE';

            List<TemplateElement> parsedElements = [];
            dynamic rawElements = s['elements'];
            if (rawElements != null) {
              if (rawElements is String) {
                try {
                  rawElements = jsonDecode(rawElements);
                } catch (_) {}
              }
              if (rawElements is List) {
                try {
                  parsedElements = rawElements
                      .map((e) {
                        final map = e is String ? jsonDecode(e) : (e is Map ? e : {});
                        return TemplateElement.fromJson(Map<String, dynamic>.from(map as Map));
                      })
                      .toList();
                } catch (e) {
                  debugPrint('[ADMIN REPO] Elements parsing error in getServices: $e');
                }
              }
            }

            return ServiceModel(
              id: (s['id'] ?? '').toString(),
              code: (s['code'] ?? s['id'] ?? 'CUSTOM_SRV').toString().toUpperCase(),
              name: (s['name'] ?? s['title'] ?? 'Custom Service').toString(),
              description: (s['description'] ?? '').toString(),
              icon: 'settings_suggest_rounded',
              isActive: s['isActive'] ?? s['isPublished'] ?? true,
              currentVersion: _toInt(s['version'], 1),
              pricing: PricingConfig.calculate(
                buyerPrice: buyerPrice,
                unitPrice: buyerPrice,
                adminMarginPercent: marginVal,
                marginType: marginType,
              ),
              elements: parsedElements,
              reviewMode: (s['reviewMode'] ?? 'MANUAL').toString().toUpperCase(),
              minCompleteHours: _toInt(s['minCompleteHours'] ?? s['min_complete_hours'], 24),
              maxCompleteHours: _toInt(s['maxCompleteHours'] ?? s['max_complete_hours'], 72),
              minAcceptHours: _toInt(s['minAcceptHours'] ?? s['min_accept_hours'], 1),
              maxAcceptHours: _toInt(s['maxAcceptHours'] ?? s['max_accept_hours'], 24),
              minDurationSeconds: _toInt(s['minDurationSeconds'] ?? s['min_duration_seconds'], 60),
              maxDurationSeconds: _toInt(s['maxDurationSeconds'] ?? s['max_duration_seconds'], 86400),
              videoTutorialUrl: s['videoTutorialUrl']?.toString() ?? s['video_tutorial_url']?.toString(),
              audioGuideUrl: s['audioGuideUrl']?.toString() ?? s['audio_guide_url']?.toString(),
              adminInstructions: s['adminInstructions']?.toString() ?? s['admin_instructions']?.toString(),
              linkFieldLabel: s['linkFieldLabel']?.toString() ?? s['link_field_label']?.toString() ?? 'Target Link / URL',
              linkFieldPlaceholder: s['linkFieldPlaceholder']?.toString() ?? s['link_field_placeholder']?.toString() ?? 'https://...',
              textFieldLabel: s['textFieldLabel']?.toString() ?? s['text_field_label']?.toString() ?? 'Custom Text / Instructions',
              textFieldPlaceholder: s['textFieldPlaceholder']?.toString() ?? s['text_field_placeholder']?.toString() ?? 'Enter text, comments or keywords...',
              workerLimit: _toInt(s['workerLimit'] ?? s['worker_limit'], 10),
              workerLimitOptions: _parseIntList(s['workerLimitOptions'] ?? s['worker_limit_options'], [5, 10, 20, 25, 50]),
              watchtimeSeconds: _toInt(s['watchtimeSeconds'] ?? s['watchtime_seconds'], 0),
              updatedAt: s['updatedAt'] != null ? DateTime.tryParse(s['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
            );
          }).toList();

          if (remoteServices.isNotEmpty) {
            return remoteServices;
          }
        }
      } catch (e) {
        debugPrint('[ADMIN REPO] Remote services fetch exception: $e');
        rethrow;
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
          final dynamic raw = response.data['service'] ?? response.data['data'] ?? response.data;
          final Map<String, dynamic> s = Map<String, dynamic>.from(raw as Map);
          final dynamic activePricing = response.data['activePricing'] ?? s['activePricing'] ?? s['pricing'];
          final Map<String, dynamic>? pricingMap = activePricing != null ? Map<String, dynamic>.from(activePricing as Map) : null;

          final double buyerPrice = pricingMap != null
              ? _toDouble(pricingMap['buyerUnitPrice'] ?? pricingMap['buyerPrice'], 0.0)
              : 0.0;
          final double marginVal = pricingMap != null
              ? _toDouble(pricingMap['marginValue'] ?? pricingMap['adminMarginPercent'], 0.0)
              : 0.0;
          final String marginType = pricingMap?['marginType']?.toString() ?? 'PERCENTAGE';

          List<TemplateElement> parsedElements = [];
          dynamic rawElements = s['elements'];
          if (rawElements != null) {
            if (rawElements is String) {
              try {
                rawElements = jsonDecode(rawElements);
              } catch (_) {}
            }
            if (rawElements is List) {
              try {
                parsedElements = rawElements
                    .map((e) {
                      final map = e is String ? jsonDecode(e) : (e is Map ? e : {});
                      return TemplateElement.fromJson(Map<String, dynamic>.from(map as Map));
                    })
                    .toList();
              } catch (e) {
                debugPrint('[ADMIN REPO] Elements parsing error in getServiceById: $e');
              }
            }
          }

          return ServiceModel(
            id: (s['id'] ?? id).toString(),
            code: (s['code'] ?? s['id'] ?? id).toString().toUpperCase(),
            name: (s['name'] ?? s['title'] ?? 'Custom Service').toString(),
            description: (s['description'] ?? '').toString(),
            icon: 'settings_suggest_rounded',
            isActive: s['isActive'] ?? s['isPublished'] ?? true,
            currentVersion: _toInt(s['version'], 1),
            pricing: PricingConfig.calculate(
              buyerPrice: buyerPrice,
              unitPrice: buyerPrice,
              adminMarginPercent: marginVal,
              marginType: marginType,
            ),
            elements: parsedElements,
            reviewMode: (s['reviewMode'] ?? 'MANUAL').toString().toUpperCase(),
            minCompleteHours: _toInt(s['minCompleteHours'] ?? s['min_complete_hours'], 24),
            maxCompleteHours: _toInt(s['maxCompleteHours'] ?? s['max_complete_hours'], 72),
            minAcceptHours: _toInt(s['minAcceptHours'] ?? s['min_accept_hours'], 1),
            maxAcceptHours: _toInt(s['maxAcceptHours'] ?? s['max_accept_hours'], 24),
            minDurationSeconds: _toInt(s['minDurationSeconds'] ?? s['min_duration_seconds'], 60),
            maxDurationSeconds: _toInt(s['maxDurationSeconds'] ?? s['max_duration_seconds'], 86400),
            videoTutorialUrl: s['videoTutorialUrl']?.toString() ?? s['video_tutorial_url']?.toString(),
            audioGuideUrl: s['audioGuideUrl']?.toString() ?? s['audio_guide_url']?.toString(),
            adminInstructions: s['adminInstructions']?.toString() ?? s['admin_instructions']?.toString(),
            linkFieldLabel: s['linkFieldLabel']?.toString() ?? s['link_field_label']?.toString() ?? 'Target Link / URL',
            linkFieldPlaceholder: s['linkFieldPlaceholder']?.toString() ?? s['link_field_placeholder']?.toString() ?? 'https://...',
            textFieldLabel: s['textFieldLabel']?.toString() ?? s['text_field_label']?.toString() ?? 'Custom Text / Instructions',
            textFieldPlaceholder: s['textFieldPlaceholder']?.toString() ?? s['text_field_placeholder']?.toString() ?? 'Enter text, comments or keywords...',
            watchtimeSeconds: _toInt(s['watchtimeSeconds'] ?? s['watchtime_seconds'], 0),
            updatedAt: s['updatedAt'] != null ? DateTime.tryParse(s['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
          );
        }
      } catch (e) {
        debugPrint('[ADMIN REPO] Remote getServiceById exception: $e');
        rethrow;
      }
    }

    if (_mockServices.isEmpty) {
        throw Exception('Service not found');
    }
    return _mockServices.firstWhere(
      (s) => s.id == id,
      orElse: () => _mockServices.first,
    );
  }

  @override
  Future<ServiceModel> saveServiceDraft(ServiceModel service) async {
    if (dioClient != null) {
      final elementsJson = service.elements.map((e) => e.toJson()).toList();

      // Dynamic unit price based on selected pricing model
      double dynamicBuyerUnitPrice = service.pricing.buyerPrice;
      if (service.pricing.modelType == PricingModelType.countBased) {
        dynamicBuyerUnitPrice = service.pricing.unitPrice > 0 ? service.pricing.unitPrice : service.pricing.buyerPrice;
      } else if (service.pricing.modelType == PricingModelType.tieredChips && service.pricing.chips.isNotEmpty) {
        dynamicBuyerUnitPrice = service.pricing.chips.first.price;
      }

      final payload = {
        'code': service.code.isNotEmpty ? service.code : 'SRV_${DateTime.now().millisecondsSinceEpoch}',
        'name': service.name,
        'description': service.description,
        'buyerUnitPrice': dynamicBuyerUnitPrice,
        'marginType': service.pricing.marginType,
        'marginValue': service.pricing.adminMarginPercent,
        'workerReward': service.pricing.workerReward,
        'workerLimit': service.workerLimit,
        'workerLimitOptions': service.workerLimitOptions,
        'elements': elementsJson,
        'reviewMode': service.reviewMode,
        'isActive': service.isActive,
        'minCompleteHours': service.minCompleteHours,
        'maxCompleteHours': service.maxCompleteHours,
        'minAcceptHours': service.minAcceptHours,
        'maxAcceptHours': service.maxAcceptHours,
        'minDurationSeconds': service.minDurationSeconds,
        'maxDurationSeconds': service.maxDurationSeconds,
        'videoTutorialUrl': service.videoTutorialUrl,
        'audioGuideUrl': service.audioGuideUrl,
        'adminInstructions': service.adminInstructions,
        'linkFieldLabel': service.linkFieldLabel,
        'linkFieldPlaceholder': service.linkFieldPlaceholder,
        'textFieldLabel': service.textFieldLabel,
        'textFieldPlaceholder': service.textFieldPlaceholder,
        'watchtimeSeconds': service.watchtimeSeconds,
      };

      // Determine if this is an existing server service (has UUID format) or a new local draft
      final bool isExistingServerService = service.id.isNotEmpty &&
          !service.id.startsWith('srv_') &&
          !service.id.startsWith('mock_');

      if (isExistingServerService) {
        // UPDATE existing service on server
        await dioClient!.patch('/admin/services/${service.id}', data: {
          'name': service.name,
          'description': service.description,
          'isActive': service.isActive,
          'elements': elementsJson,
          'reviewMode': service.reviewMode,
          'workerLimit': service.workerLimit,
          'workerLimitOptions': service.workerLimitOptions,
          'minCompleteHours': service.minCompleteHours,
          'maxCompleteHours': service.maxCompleteHours,
          'minAcceptHours': service.minAcceptHours,
          'maxAcceptHours': service.maxAcceptHours,
          'minDurationSeconds': service.minDurationSeconds,
          'maxDurationSeconds': service.maxDurationSeconds,
          'videoTutorialUrl': service.videoTutorialUrl,
          'audioGuideUrl': service.audioGuideUrl,
          'adminInstructions': service.adminInstructions,
          'linkFieldLabel': service.linkFieldLabel,
          'linkFieldPlaceholder': service.linkFieldPlaceholder,
          'textFieldLabel': service.textFieldLabel,
          'textFieldPlaceholder': service.textFieldPlaceholder,
          'watchtimeSeconds': service.watchtimeSeconds,
        });
        if (dynamicBuyerUnitPrice > 0) {
          await dioClient!.post('/admin/services/${service.id}/pricing', data: {
            'buyerUnitPrice': dynamicBuyerUnitPrice,
            'marginType': service.pricing.marginType,
            'marginValue': service.pricing.adminMarginPercent,
            'workerReward': service.pricing.workerReward,
          });
        }

        // Update local cache
        final index = _mockServices.indexWhere((s) => s.id == service.id);
        if (index >= 0) {
          _mockServices[index] = service;
        } else {
          _mockServices.add(service);
        }
        return service;
      } else {
        // CREATE new service on server and extract the real server UUID
        final response = await dioClient!.post('/admin/services', data: payload);
        debugPrint('[ADMIN REPO] Remote saveServiceDraft response: ${response.data}');

        // Extract the real server-generated ID from response
        String serverId = service.id;
        if (response.data != null && response.data['service'] != null) {
          final serverService = response.data['service'];
          if (serverService['id'] != null) {
            serverId = serverService['id'].toString();
          }
        }

        final savedService = service.copyWith(id: serverId);

        // Update local cache with server ID
        final index = _mockServices.indexWhere((s) => s.id == service.id);
        if (index >= 0) {
          _mockServices[index] = savedService;
        } else {
          _mockServices.add(savedService);
        }
        return savedService;
      }
    }

    // Offline-only fallback (no dioClient)
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
    if (dioClient != null) {
      try {
        ServiceModel serviceToPublish;
        if (serviceId.isNotEmpty && !serviceId.startsWith('srv_') && !serviceId.startsWith('mock_')) {
          serviceToPublish = await getServiceById(serviceId);
        } else {
          final cachedIdx = _mockServices.indexWhere((s) => s.id == serviceId);
          if (cachedIdx >= 0) {
            serviceToPublish = _mockServices[cachedIdx];
          } else {
            throw Exception('Service draft not found');
          }
        }

        final published = serviceToPublish.copyWith(
          isActive: true,
          currentVersion: serviceToPublish.currentVersion + 1,
          updatedAt: DateTime.now(),
        );
        // Save the updated version back to server
        return await saveServiceDraft(published);
      } catch (e) {
        debugPrint('[ADMIN REPO] publishServiceVersion server error: $e');
        rethrow;
      }
    }

    // Offline-only fallback
    final index = _mockServices.indexWhere((s) => s.id == serviceId);
    if (index >= 0) {
      final existing = _mockServices[index];
      final published = existing.copyWith(
        isActive: true,
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
    if (dioClient != null) {
      try {
        await dioClient!.delete('/admin/services/$serviceId');
      } catch (e) {
        debugPrint('[ADMIN REPO] deleteService server error: $e');
        rethrow;
      }
    }
    _mockServices.removeWhere((s) => s.id == serviceId);
  }
}

