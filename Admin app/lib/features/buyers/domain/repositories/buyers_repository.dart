import '../../data/models/buyer_model.dart';
import '../../data/datasources/buyers_remote_datasource.dart';

abstract class BuyersRepository {
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

class BuyersRepositoryImpl implements BuyersRepository {
  final BuyersRemoteDataSource remoteDataSource;

  BuyersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<BuyerModel>> getBuyers() => remoteDataSource.getBuyers();

  @override
  Future<BuyerModel> getBuyerDetail(String buyerId) => remoteDataSource.getBuyerDetail(buyerId);

  @override
  Future<void> updateBuyerStatus(String buyerId, String status) =>
      remoteDataSource.updateBuyerStatus(buyerId, status);

  @override
  Future<List<dynamic>> getBuyerOrders(String buyerId) => remoteDataSource.getBuyerOrders(buyerId);

  @override
  Future<List<dynamic>> getBuyerTasks(String buyerId) => remoteDataSource.getBuyerTasks(buyerId);

  @override
  Future<List<dynamic>> getBuyerPayments(String buyerId) => remoteDataSource.getBuyerPayments(buyerId);

  @override
  Future<List<dynamic>> getBuyerActivity(String buyerId) => remoteDataSource.getBuyerActivity(buyerId);

  @override
  Future<Map<String, dynamic>> getBuyerAnalytics(String buyerId) => remoteDataSource.getBuyerAnalytics(buyerId);

  @override
  Future<void> adjustBuyerBalance(String buyerId, double amount, String reason) =>
      remoteDataSource.adjustBuyerBalance(buyerId, amount, reason);
}
