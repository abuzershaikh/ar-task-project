import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/review_remote_datasource.dart';
import '../models/review_submission_model.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<ReviewSubmissionModel>>> getPendingReviews();
  Future<Either<Failure, ReviewSubmissionModel>> getReviewDetail(String submissionId);
  Future<Either<Failure, bool>> approveTaskProof(String submissionId, {String? notes});
  Future<Either<Failure, bool>> rejectTaskProof(String submissionId, String reasonCode, String note);
}

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ReviewSubmissionModel>>> getPendingReviews() async {
    try {
      final reviews = await remoteDataSource.getPendingReviews();
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReviewSubmissionModel>> getReviewDetail(String submissionId) async {
    try {
      final detail = await remoteDataSource.getReviewDetail(submissionId);
      return Right(detail);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> approveTaskProof(String submissionId, {String? notes}) async {
    try {
      final success = await remoteDataSource.approveSubmission(submissionId, notes: notes);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> rejectTaskProof(String submissionId, String reasonCode, String note) async {
    try {
      final success = await remoteDataSource.rejectSubmission(submissionId, reasonCode, note);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
