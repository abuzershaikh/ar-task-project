import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/support_remote_datasource.dart';
import '../models/support_ticket_model.dart';

abstract class SupportRepository {
  Future<Either<Failure, List<SupportTicketModel>>> getTickets();
  Future<Either<Failure, bool>> createTicket(String subject, String category, String message);
}

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource remoteDataSource;

  SupportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<SupportTicketModel>>> getTickets() async {
    try {
      final tickets = await remoteDataSource.getTickets();
      return Right(tickets);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> createTicket(String subject, String category, String message) async {
    try {
      final result = await remoteDataSource.createTicket(subject, category, message);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
