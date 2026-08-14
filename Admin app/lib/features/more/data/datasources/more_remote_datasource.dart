import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/more_models.dart';

abstract class MoreRemoteDataSource {
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

class MoreRemoteDataSourceImpl implements MoreRemoteDataSource {
  final DioClient _dioClient;

  MoreRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<KycItemModel>> getPendingKycQueue() async {
    final response = await _dioClient.get(ApiEndpoints.kyc);
    final list = (response.data['applications'] ?? response.data['data'] ?? []) as List;
    return list.map((e) => KycItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> verifyKyc(String kycId) async {
    await _dioClient.post(ApiEndpoints.kycVerify(kycId));
  }

  @override
  Future<void> rejectKyc(String kycId, String reason) async {
    await _dioClient.post(ApiEndpoints.kycReject(kycId), data: {'reason': reason});
  }

  @override
  Future<List<PayoutItemModel>> getPendingPayoutsQueue() async {
    final response = await _dioClient.get(ApiEndpoints.payouts);
    final list = (response.data['withdrawals'] ?? response.data['data'] ?? []) as List;
    return list.map((e) => PayoutItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> processPayout(String payoutId) async {
    await _dioClient.post(ApiEndpoints.payoutProcess(payoutId));
  }

  @override
  Future<void> rejectPayout(String payoutId, String reason) async {
    await _dioClient.post(ApiEndpoints.payoutReject(payoutId), data: {'reason': reason});
  }

  @override
  Future<List<ReviewItemModel>> getPendingReviewsQueue() async {
    final response = await _dioClient.get(ApiEndpoints.reviews);
    final list = (response.data['submissions'] ?? response.data['data'] ?? []) as List;
    return list.map((e) => ReviewItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> approveReview(String reviewId) async {
    await _dioClient.post(ApiEndpoints.reviewApprove(reviewId));
  }

  @override
  Future<void> rejectReview(String reviewId, String reason) async {
    await _dioClient.post(ApiEndpoints.reviewReject(reviewId), data: {'reason': reason});
  }

  @override
  Future<List<AuditLogItemModel>> getAuditLogs() async {
    final response = await _dioClient.get(ApiEndpoints.auditLogs);
    final list = (response.data['items'] ?? response.data['data'] ?? []) as List;
    return list.map((e) => AuditLogItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
