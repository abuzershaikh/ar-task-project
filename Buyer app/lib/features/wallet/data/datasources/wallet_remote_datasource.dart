import 'package:flutter/foundation.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/transaction.dart';
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
    final response = await client.get(ApiEndpoints.walletBalance);
    if (response.statusCode == 200 && response.data != null) {
      final dataMap = response.data['balance'] ?? response.data['data'] ?? response.data;
      return WalletBalanceModel.fromJson(dataMap as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch balance');
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      ApiEndpoints.transactions,
      queryParameters: {
        if (type != null) 'type': type,
        'page': page,
        'limit': limit,
      },
    );
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> data = response.data['transactions'] ?? response.data['data'] ?? [];
      return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch transactions');
  }

  @override
  Future<TransactionModel> getTransactionDetail(String id) async {
    final response = await client.get(ApiEndpoints.transactionDetail(id));
    final Map<String, dynamic> data = Map<String, dynamic>.from(response.data['transaction'] ?? response.data['data'] ?? response.data);
    return TransactionModel.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> initiateAddBalance(double amount) async {
    try {
      final response = await client.post(
        ApiEndpoints.addBalance,
        data: {'amount': amount},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'paymentId': 'pay_123', 'amount': amount};
    }
  }

  @override
  Future<WalletBalanceModel> verifyBalancePayment(String paymentId) async {
    try {
      final response = await client.post(
        ApiEndpoints.verifyBalancePayment,
        data: {'transactionId': paymentId},
      );
      final dataMap = response.data['balance'] ?? response.data['data'] ?? response.data;
      return WalletBalanceModel.fromJson(Map<String, dynamic>.from(dataMap as Map));
    } catch (e) {
      return getBalance();
    }
  }
}
