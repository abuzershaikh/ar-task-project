import '../models/service_model.dart';

/// ServiceRepository Interface (Enterprise Clean Architecture)
/// Buyer app me published services load aur fetch karne ke liye standard contract.
abstract class ServiceRepository {
  /// Sabhi active published services fetch karne ka method
  Future<List<ServiceModel>> getPublishedServices();

  /// Specific service ID se service details get karna
  Future<ServiceModel?> getServiceById(String serviceId);
}
