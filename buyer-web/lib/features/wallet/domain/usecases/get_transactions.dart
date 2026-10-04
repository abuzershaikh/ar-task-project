import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';
import '../repositories/wallet_repository.dart';

class GetTransactions {
  final WalletRepository repository;

  GetTransactions(this.repository);

  Future<Either<Failure, List<Transaction>>> call({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getTransactions(
      type: type,
      page: page,
      limit: limit,
    );
  }
}
