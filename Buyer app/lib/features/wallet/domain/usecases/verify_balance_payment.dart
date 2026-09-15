import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_balance.dart';
import '../repositories/wallet_repository.dart';

class VerifyBalancePayment {
  final WalletRepository repository;

  VerifyBalancePayment(this.repository);

  Future<Either<Failure, WalletBalance>> call(
    String paymentId, {
    String? orderId,
    String? signature,
    double? amount,
  }) async {
    return await repository.verifyBalancePayment(
      paymentId,
      orderId: orderId,
      signature: signature,
      amount: amount,
    );
  }
}
