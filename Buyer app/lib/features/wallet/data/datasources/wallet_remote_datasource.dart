import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
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
  final DioClient client;

  WalletRemoteDataSourceImpl({required this.client});

  @override
  Future<WalletBalanceModel> getBalance() async {
    try {
      final response = await client.get(ApiEndpoints.walletBalance);
      return WalletBalanceModel.fromJson(response.data['data']);
    } on NotFoundException {
      debugPrint('[WALLET DATA] Balance endpoint not found. Returning empty wallet.');
      return WalletBalanceModel.empty();
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
      final response = await client.get(
        ApiEndpoints.transactions,
        queryParameters: {
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } on NotFoundException {
      debugPrint('[WALLET DATA] Transactions endpoint not found. Returning empty list.');
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TransactionModel> getTransactionDetail(String id) async {
    try {
      final response = await client.get(ApiEndpoints.transactionDetail(id));
      return TransactionModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> initiateAddBalance(double amount) async {
    try {
      final response = await client.post(
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
      final response = await client.post(
        ApiEndpoints.verifyBalancePayment,
        data: {'paymentId': paymentId},
      );
      return WalletBalanceModel.fromJson(response.data['data']['balance']);
    } catch (e) {
      rethrow;
    }
  }
}
