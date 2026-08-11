import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class AddBalance {
  final WalletRepository repository;

  AddBalance(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(double amount) async {
    return await repository.initiateAddBalance(amount);
  }
}
