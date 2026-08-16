import '../../data/models/buyer_model.dart';
import '../../data/datasources/buyers_remote_datasource.dart';

import '../../data/datasources/buyers_local_datasource.dart';

abstract class BuyersRepository {
  Future<List<BuyerModel>> getBuyers({bool forceRefresh = false});
  Future<BuyerModel> getBuyerDetail(String buyerId, {bool forceRefresh = false});
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
  final BuyersLocalDataSource localDataSource;

  BuyersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<BuyerModel>> getBuyers({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final localData = await localDataSource.getCachedBuyers();
      if (localData.isNotEmpty) {
        remoteDataSource.getBuyers().then((remoteBuyers) {
          localDataSource.cacheBuyers(remoteBuyers);
        }).catchError((_) {});
        return localData;
      }
    }
    
    final remoteBuyers = await remoteDataSource.getBuyers();
    await localDataSource.cacheBuyers(remoteBuyers);
    return remoteBuyers;
  }

  @override
  Future<BuyerModel> getBuyerDetail(String buyerId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final localData = await localDataSource.getCachedBuyerDetail(buyerId);
      if (localData != null) {
        remoteDataSource.getBuyerDetail(buyerId).then((remoteBuyer) async {
          final fullDetail = remoteBuyer.toJson();
          final orders = await remoteDataSource.getBuyerOrders(buyerId).catchError((_) => []);
          fullDetail['orders_cache'] = orders;
          await localDataSource.cacheBuyerDetail(buyerId, fullDetail);
        }).catchError((_) {});
        return localData;
      }
    }

    final remoteBuyer = await remoteDataSource.getBuyerDetail(buyerId);
    final fullDetail = remoteBuyer.toJson();
    final orders = await remoteDataSource.getBuyerOrders(buyerId).catchError((_) => []);
    fullDetail['orders_cache'] = orders;
    await localDataSource.cacheBuyerDetail(buyerId, fullDetail);
    return remoteBuyer;
  }

  @override
  Future<void> updateBuyerStatus(String buyerId, String status) =>
      remoteDataSource.updateBuyerStatus(buyerId, status);

  @override
  Future<List<dynamic>> getBuyerOrders(String buyerId) async {
    try {
      return await remoteDataSource.getBuyerOrders(buyerId);
    } catch (_) {
      final localData = await localDataSource.getCachedBuyerFullDetail(buyerId);
      if (localData != null && localData.containsKey('orders_cache')) {
        return localData['orders_cache'] as List<dynamic>;
      }
      return [];
    }
  }

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
