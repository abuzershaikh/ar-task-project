import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/wallet_balance_model.dart';
import '../models/transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletBalanceModel> getBalance();
  Future<List<TransactionModel>> getTransactions({
    String? type,
    int page = 1,
    int limit = 20,
  });
  Future<TransactionModel> getTransactionDetail(String id);
  Future<Map<String, dynamic>> initiateAddBalance(double amount);
  Future<WalletBalanceModel> verifyBalancePayment(String paymentId);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final Dio dio;

  WalletRemoteDataSourceImpl({required this.dio});

  @override
  Future<WalletBalanceModel> getBalance() async {
    try {
      final response = await dio.get(ApiEndpoints.walletBalance);
      return WalletBalanceModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.transactions,
        queryParameters: {
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TransactionModel> getTransactionDetail(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.transactionDetail(id));
      return TransactionModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> initiateAddBalance(double amount) async {
    try {
      final response = await dio.post(
        ApiEndpoints.addBalance,
        data: {'amount': amount},
      );
      return response.data['data'];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WalletBalanceModel> verifyBalancePayment(String paymentId) async {
    try {
      final response = await dio.post(
        ApiEndpoints.verifyBalancePayment,
        data: {'paymentId': paymentId},
      );
      return WalletBalanceModel.fromJson(response.data['data']['balance']);
    } catch (e) {
      rethrow;
    }
  }
}
