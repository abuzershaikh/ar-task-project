import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/campaign_detail.dart';
import '../../domain/repositories/campaign_repository.dart';
import '../datasources/campaign_remote_datasource.dart';

class CampaignRepositoryImpl implements CampaignRepository {
  final CampaignRemoteDataSource remoteDataSource;

  CampaignRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CampaignDetail>>> getCampaigns({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final models = await remoteDataSource.getCampaigns(
        status: status,
        page: page,
        limit: limit,
      );
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CampaignDetail>> getCampaignDetail(String id) async {
    try {
      final model = await remoteDataSource.getCampaignDetail(id);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getCampaignTasks(
    String id, {
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final tasks = await remoteDataSource.getCampaignTasks(
        id,
        status: status,
        page: page,
        limit: limit,
      );
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getCampaignReviews(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final reviews = await remoteDataSource.getCampaignReviews(
        id,
        page: page,
        limit: limit,
      );
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getCampaignActivity(String id) async {
    try {
      final activity = await remoteDataSource.getCampaignActivity(id);
      return Right(activity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCampaignAnalytics(
    String id,
  ) async {
    try {
      final analytics = await remoteDataSource.getCampaignAnalytics(id);
      return Right(analytics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CampaignDetail>> pauseCampaign(String id) async {
    try {
      final model = await remoteDataSource.pauseCampaign(id);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CampaignDetail>> resumeCampaign(String id) async {
    try {
      final model = await remoteDataSource.resumeCampaign(id);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelCampaign(String id) async {
    try {
      await remoteDataSource.cancelCampaign(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CampaignDetail>> createCampaign({
    required String serviceId,
    required String name,
    required int quantity,
    required String instructions,
    required List<String> proofRequirements,
    required int acceptWithinHours,
    required int completeWithinHours,
    required DateTime deadline,
    required String reviewMode,
  }) async {
    try {
      final model = await remoteDataSource.createCampaign(
        serviceId: serviceId,
        name: name,
        quantity: quantity,
        instructions: instructions,
        proofRequirements: proofRequirements,
        acceptWithinHours: acceptWithinHours,
        completeWithinHours: completeWithinHours,
        deadline: deadline,
        reviewMode: reviewMode,
      );
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
