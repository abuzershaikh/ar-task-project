import '../models/service_model.dart';

abstract class ServiceBuilderRepository {
  Future<List<ServiceModel>> getServices();
  Future<ServiceModel> getServiceById(String id);
  Future<ServiceModel> saveServiceDraft(ServiceModel service);
  Future<ServiceModel> publishServiceVersion(String serviceId);
  Future<void> deleteService(String serviceId);
}
