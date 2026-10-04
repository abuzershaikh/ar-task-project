import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';
import '../entities/wallet_balance.dart';

abstract class WalletRepository {
  /// Get current wallet balance
  Future<Either<Failure, WalletBalance>> getBalance();

  /// Get transaction history with optional filters
  Future<Either<Failure, List<Transaction>>> getTransactions({
    String? type,
    int page = 1,
    int limit = 20,
  });

  /// Get transaction detail by ID
  Future<Either<Failure, Transaction>> getTransactionDetail(String id);

  /// Initiate add balance flow (returns payment gateway data)
  Future<Either<Failure, Map<String, dynamic>>> initiateAddBalance(
    double amount,
  );

  /// Verify balance payment after payment gateway callback
  Future<Either<Failure, WalletBalance>> verifyBalancePayment(
    String paymentId,
  );
}
