import '../../data/models/admin_order_model.dart';
import '../../data/datasources/orders_remote_datasource.dart';

abstract class OrdersRepository {
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

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;

  OrdersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AdminOrderModel>> getOrders() => remoteDataSource.getOrders();

  @override
  Future<AdminOrderModel> getOrderDetail(String orderId) => remoteDataSource.getOrderDetail(orderId);

  @override
  Future<List<dynamic>> getOrderTasks(String orderId) => remoteDataSource.getOrderTasks(orderId);

  @override
  Future<List<dynamic>> getOrderSubmissions(String orderId) => remoteDataSource.getOrderSubmissions(orderId);

  @override
  Future<void> pauseOrder(String orderId) => remoteDataSource.pauseOrder(orderId);

  @override
  Future<void> resumeOrder(String orderId) => remoteDataSource.resumeOrder(orderId);

  @override
  Future<void> cancelOrder(String orderId, String reason) => remoteDataSource.cancelOrder(orderId, reason);

  @override
  Future<void> approveReview(String submissionId, String notes) =>
      remoteDataSource.approveReview(submissionId, notes);

  @override
  Future<void> rejectReview(String submissionId, String notes) =>
      remoteDataSource.rejectReview(submissionId, notes);
}
