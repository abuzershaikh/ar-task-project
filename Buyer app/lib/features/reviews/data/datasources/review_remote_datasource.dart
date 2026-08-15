import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_submission_model.dart';

abstract class ReviewRemoteDataSource {
  Future<List<ReviewSubmissionModel>> getPendingReviews();
  Future<ReviewSubmissionModel> getReviewDetail(String submissionId);
  Future<bool> approveSubmission(String submissionId, {String? notes});
  Future<bool> rejectSubmission(String submissionId, String reasonCode, String note);
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
}
