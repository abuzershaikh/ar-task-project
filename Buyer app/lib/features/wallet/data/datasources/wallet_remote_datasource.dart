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
  Future<WalletBalanceModel> verifyBalancePayment(
    String paymentId, {
    String? orderId,
    String? signature,
    double? amount,
  });
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
        if (type != null && type.trim().isNotEmpty && type.trim().toLowerCase() != 'all')
          'type': type.trim(),
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
    final response = await client.post(
      ApiEndpoints.razorpayOrder,
      data: {'amount': amount},
    );
    if (response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Failed to initiate Razorpay order');
  }

  @override
  Future<WalletBalanceModel> verifyBalancePayment(
    String paymentId, {
    String? orderId,
    String? signature,
    double? amount,
  }) async {
    final response = await client.post(
      ApiEndpoints.razorpayVerify,
      data: {
        'paymentId': paymentId,
        'orderId': orderId ?? paymentId,
        'signature': signature ?? '',
        if (amount != null) 'amount': amount,
      },
    );
    if (response.data != null) {
      final dataMap = response.data['balance'] ?? response.data['data'] ?? response.data;
      return WalletBalanceModel.fromJson(Map<String, dynamic>.from(dataMap as Map));
    }
    return getBalance();
  }

  Future<Map<String, dynamic>> createRazorpayOrder(double amount, {String? description}) async {
    final response = await client.post(
      ApiEndpoints.razorpayOrder,
      data: {
        'amount': amount,
        if (description != null) 'description': description,
      },
    );
    if (response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Failed to create Razorpay order');
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amount,
  }) async {
    final response = await client.post(
      ApiEndpoints.razorpayVerify,
      data: {
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'amount': amount,
      },
    );
    if (response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Failed to verify Razorpay payment');
  }
}
