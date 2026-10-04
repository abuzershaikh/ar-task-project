import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/analytics_remote_datasource.dart';
import '../models/analytics_model.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, AnalyticsModel>> getAnalytics();
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  AnalyticsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AnalyticsModel>> getAnalytics() async {
    try {
      final analytics = await remoteDataSource.getAnalytics();
      return Right(analytics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
