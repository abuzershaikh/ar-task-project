import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, DashboardData>> getDashboardData() async {
    try {
      final result = await remoteDataSource.getDashboardData();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Unable to load dashboard data: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> refreshDashboard() async {
    return await getDashboardData();
  }
}
