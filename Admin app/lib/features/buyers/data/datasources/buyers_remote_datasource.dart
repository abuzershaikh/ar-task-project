import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/buyer_model.dart';

abstract class BuyersRemoteDataSource {
  Future<List<BuyerModel>> getBuyers();
  Future<BuyerModel> getBuyerDetail(String buyerId);
  Future<void> updateBuyerStatus(String buyerId, String status);
  Future<List<dynamic>> getBuyerOrders(String buyerId);
  Future<List<dynamic>> getBuyerTasks(String buyerId);
  Future<List<dynamic>> getBuyerPayments(String buyerId);
  Future<List<dynamic>> getBuyerActivity(String buyerId);
  Future<Map<String, dynamic>> getBuyerAnalytics(String buyerId);
  Future<void> adjustBuyerBalance(String buyerId, double amount, String reason);
}

class BuyersRemoteDataSourceImpl implements BuyersRemoteDataSource {
  final DioClient _dioClient;

  BuyersRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<BuyerModel>> getBuyers() async {
    final response = await _dioClient.get(ApiEndpoints.buyers);
    final list = (response.data['buyers'] as List?) ?? [];
    return list.map((item) => BuyerModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<BuyerModel> getBuyerDetail(String buyerId) async {
    final response = await _dioClient.get(ApiEndpoints.buyerById(buyerId));
    final data = Map<String, dynamic>.from(response.data['buyer'] ?? response.data);
    data['metrics'] = response.data['metrics'];
    return BuyerModel.fromJson(data);
  }

  @override
  Future<void> updateBuyerStatus(String buyerId, String status) async {
    await _dioClient.post(
      '${ApiEndpoints.buyers}/$buyerId/status',
      data: {'status': status},
    );
  }

  @override
  Future<List<dynamic>> getBuyerOrders(String buyerId) async {
    final response = await _dioClient.get('${ApiEndpoints.buyers}/$buyerId/orders');
    return (response.data['orders'] as List?) ?? [];
  }

  @override
  Future<List<dynamic>> getBuyerTasks(String buyerId) async {
    final response = await _dioClient.get('${ApiEndpoints.buyers}/$buyerId/tasks');
    return (response.data['tasks'] as List?) ?? [];
  }

  @override
  Future<List<dynamic>> getBuyerPayments(String buyerId) async {
    final response = await _dioClient.get('${ApiEndpoints.buyers}/$buyerId/payments');
    return (response.data['payments'] as List?) ?? [];
  }

  @override
  Future<List<dynamic>> getBuyerActivity(String buyerId) async {
    final response = await _dioClient.get('${ApiEndpoints.buyers}/$buyerId/activity');
    return (response.data['activity'] as List?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getBuyerAnalytics(String buyerId) async {
    final response = await _dioClient.get('${ApiEndpoints.buyers}/$buyerId/analytics');
    return Map<String, dynamic>.from(response.data['analytics'] ?? response.data ?? {});
  }

  @override
  Future<void> adjustBuyerBalance(String buyerId, double amount, String reason) async {
    await _dioClient.post(
      ApiEndpoints.buyerBalanceAdjust(buyerId),
      data: {'amount': amount, 'reason': reason},
    );
  }
}
