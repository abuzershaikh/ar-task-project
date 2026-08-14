import '../../data/models/more_models.dart';
import '../../data/datasources/more_remote_datasource.dart';

abstract class MoreRepository {
  Future<List<KycItemModel>> getPendingKycQueue();
  Future<void> verifyKyc(String kycId);
  Future<void> rejectKyc(String kycId, String reason);

  Future<List<PayoutItemModel>> getPendingPayoutsQueue();
  Future<void> processPayout(String payoutId);
  Future<void> rejectPayout(String payoutId, String reason);

  Future<List<ReviewItemModel>> getPendingReviewsQueue();
  Future<void> approveReview(String reviewId);
  Future<void> rejectReview(String reviewId, String reason);

  Future<List<AuditLogItemModel>> getAuditLogs();
}

class MoreRepositoryImpl implements MoreRepository {
  final MoreRemoteDataSource remoteDataSource;

  MoreRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<KycItemModel>> getPendingKycQueue() => remoteDataSource.getPendingKycQueue();

  @override
  Future<void> verifyKyc(String kycId) => remoteDataSource.verifyKyc(kycId);

  @override
  Future<void> rejectKyc(String kycId, String reason) => remoteDataSource.rejectKyc(kycId, reason);

  @override
  Future<List<PayoutItemModel>> getPendingPayoutsQueue() => remoteDataSource.getPendingPayoutsQueue();

  @override
  Future<void> processPayout(String payoutId) => remoteDataSource.processPayout(payoutId);

  @override
  Future<void> rejectPayout(String payoutId, String reason) => remoteDataSource.rejectPayout(payoutId, reason);

  @override
  Future<List<ReviewItemModel>> getPendingReviewsQueue() => remoteDataSource.getPendingReviewsQueue();

  @override
  Future<void> approveReview(String reviewId) => remoteDataSource.approveReview(reviewId);

  @override
  Future<void> rejectReview(String reviewId, String reason) => remoteDataSource.rejectReview(reviewId, reason);

  @override
  Future<List<AuditLogItemModel>> getAuditLogs() => remoteDataSource.getAuditLogs();
}
