import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_submission_model.dart';

abstract class ReviewRemoteDataSource {
  Future<List<ReviewSubmissionModel>> getPendingReviews();
  Future<ReviewSubmissionModel> getReviewDetail(String submissionId);
  Future<bool> approveSubmission(String submissionId, {String? notes});
  Future<bool> rejectSubmission(String submissionId, String reasonCode, String note);
  Future<Map<String, dynamic>> approveAllSubmissions({String? orderId, List<String>? submissionIds, String? notes});
  Future<bool> toggleAutoApprove({required bool autoApprove, String? orderId});
  Future<bool> getAutoApproveStatus({String? orderId});
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final DioClient client;

  ReviewRemoteDataSourceImpl(this.client);

  @override
  Future<List<ReviewSubmissionModel>> getPendingReviews() async {
    final response = await client.get('/buyer/reviews/pending');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data['submissions'] ?? response.data['data'] ?? [];
      return list.map((json) => ReviewSubmissionModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<ReviewSubmissionModel> getReviewDetail(String submissionId) async {
    final response = await client.get('/buyer/reviews/$submissionId');
    final data = Map<String, dynamic>.from(response.data['submission'] ?? response.data);
    return ReviewSubmissionModel.fromJson(data);
  }

  @override
  Future<bool> approveSubmission(String submissionId, {String? notes}) async {
    final response = await client.post(
      ApiEndpoints.approveSubmission(submissionId),
      data: notes != null ? {'notes': notes} : {},
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> rejectSubmission(String submissionId, String reasonCode, String note) async {
    final response = await client.post(
      ApiEndpoints.rejectSubmission(submissionId),
      data: {
        'reasonCode': reasonCode,
        'note': note,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<Map<String, dynamic>> approveAllSubmissions({String? orderId, List<String>? submissionIds, String? notes}) async {
    final response = await client.post(
      '/buyer/reviews/approve-all',
      data: {
        if (orderId != null) 'orderId': orderId,
        if (submissionIds != null) 'submissionIds': submissionIds,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data != null ? Map<String, dynamic>.from(response.data) : {'success': true};
  }

  @override
  Future<bool> toggleAutoApprove({required bool autoApprove, String? orderId}) async {
    final response = await client.post(
      '/buyer/reviews/auto-approve-toggle',
      data: {
        'autoApprove': autoApprove,
        if (orderId != null) 'orderId': orderId,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> getAutoApproveStatus({String? orderId}) async {
    final response = await client.get(
      '/buyer/reviews/auto-approve-status',
      queryParameters: orderId != null ? {'orderId': orderId} : null,
    );
    if (response.statusCode == 200 && response.data != null) {
      return response.data['autoApprove'] == true;
    }
    return false;
  }
}
