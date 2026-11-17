import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/service_model.dart';
import '../../domain/repositories/service_repository.dart';

/// ServiceRepositoryImpl (Enterprise Clean Architecture Data Layer)
/// Real backend API integration via Dio client + offline fallback templates.
class ServiceRepositoryImpl implements ServiceRepository {
  final DioClient? dioClient;

  ServiceRepositoryImpl({DioClient? dioClient})
      : dioClient = dioClient ?? (GetIt.instance.isRegistered<DioClient>() ? GetIt.instance<DioClient>() : null);

  @override
  Future<List<ServiceModel>> getPublishedServices() async {
    if (dioClient == null) throw StateError('Service catalog is unavailable');
    final response = await dioClient!.get('/buyer/services');
    if (response.statusCode != 200 || response.data is! Map) {
      throw StateError('Could not load services');
    }
    final dynamic list = response.data['services'] ?? response.data['data'];
    if (list is! List) throw StateError('Invalid service catalog response');
    // The server catalog is authoritative, including an intentionally empty list.
    return list.map((item) => ServiceModel.fromJson(
      Map<String, dynamic>.from(item as Map),
    )).where((service) {
      final identity = '${service.code} ${service.category} ${service.name}'.toUpperCase();
      return service.isActive && !identity.contains('TELEGRAM');
    }).toList();
  }

  @override
  Future<ServiceModel?> getServiceById(String serviceId) async {
    final services = await getPublishedServices();
    for (final service in services) {
      if (service.id == serviceId) return service;
    }
    return null;
  }

  /// Submit Campaign Payload to Backend API (/api/v1/buyer/orders)
  Future<bool> submitCampaignOrder(Map<String, dynamic> payloadData) async {
    if (dioClient != null) {
      try {
        final response = await dioClient!.post(
          '/buyer/orders',
          data: payloadData,
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        rethrow;
      }
    }
    return false;
  }


}
