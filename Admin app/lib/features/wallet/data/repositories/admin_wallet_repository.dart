import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';

class AdminWalletRepository {
  final DioClient _dioClient;

  AdminWalletRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? GetIt.instance<DioClient>();

  /// Fetch all buyers with their live wallet balance
  Future<List<Map<String, dynamic>>> getBuyersWithWallet({String? search}) async {
    try {
      final response = await _dioClient.get(
        '/admin/wallet/buyers',
        queryParameters: search != null && search.trim().isNotEmpty
            ? {'search': search.trim()}
            : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['buyers'] ?? [];
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  /// Top up (Credit or Debit) a buyer's wallet
  Future<Map<String, dynamic>?> topupBuyer({
    required String buyerId,
    required double amount,
    String type = 'CREDIT',
    String? notes,
  }) async {
    try {
      final response = await _dioClient.post(
        '/admin/wallet/topup',
        data: {
          'buyerId': buyerId,
          'amount': amount,
          'type': type,
          'notes': notes,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Fetch transactions for a specific buyer
  Future<List<Map<String, dynamic>>> getBuyerTransactions(String buyerId) async {
    try {
      final response = await _dioClient.get(
        '/admin/wallet/buyers/$buyerId/transactions',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['transactions'] ?? [];
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
}
