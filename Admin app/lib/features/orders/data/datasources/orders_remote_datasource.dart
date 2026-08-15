import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/admin_order_model.dart';

abstract class OrdersRemoteDataSource {
  Future<List<AdminOrderModel>> getOrders();
  Future<AdminOrderModel> getOrderDetail(String orderId);
  Future<List<dynamic>> getOrderTasks(String orderId);
  Future<List<dynamic>> getOrderSubmissions(String orderId);
  Future<void> pauseOrder(String orderId);
  Future<void> resumeOrder(String orderId);
  Future<void> cancelOrder(String orderId, String reason);
  Future<void> approveReview(String submissionId, String notes);
  Future<void> rejectReview(String submissionId, String notes);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final DioClient _dioClient;

  OrdersRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<AdminOrderModel>> getOrders() async {
    final response = await _dioClient.get(
      ApiEndpoints.orders,
      queryParameters: {'page': 1, 'limit': 50},
    );
    final list = (response.data['orders'] as List?) ?? [];
    return list.map((item) => AdminOrderModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<AdminOrderModel> getOrderDetail(String orderId) async {
    final response = await _dioClient.get(ApiEndpoints.orderById(orderId));
    final data = Map<String, dynamic>.from(response.data['order'] ?? response.data);
    return AdminOrderModel.fromJson(data);
  }

  @override
  Future<List<dynamic>> getOrderTasks(String orderId) async {
    final response = await _dioClient.get(ApiEndpoints.orderTasks(orderId));
    return (response.data['tasks'] as List?) ?? [];
  }

  @override
  Future<List<dynamic>> getOrderSubmissions(String orderId) async {
    final response = await _dioClient.get('${ApiEndpoints.orders}/$orderId/submissions');
    return (response.data['submissions'] as List?) ?? [];
  }

  @override
  Future<void> pauseOrder(String orderId) async {
    await _dioClient.post(ApiEndpoints.orderPause(orderId));
  }

  @override
  Future<void> resumeOrder(String orderId) async {
    await _dioClient.post(ApiEndpoints.orderResume(orderId));
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    await _dioClient.post(ApiEndpoints.orderCancel(orderId), data: {'reason': reason});
  }

  @override
  Future<void> approveReview(String submissionId, String notes) async {
    await _dioClient.post(ApiEndpoints.reviewApprove(submissionId), data: {'notes': notes});
  }

  @override
  Future<void> rejectReview(String submissionId, String notes) async {
    await _dioClient.post(ApiEndpoints.reviewReject(submissionId), data: {'notes': notes});
  }
}
