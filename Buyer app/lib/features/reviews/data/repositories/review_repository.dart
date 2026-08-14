import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class ReviewRepository {
  final DioClient _dioClient;

  ReviewRepository(this._dioClient);

  Future<bool> approveTaskProof(String submissionId, {String? notes}) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.approveSubmission(submissionId),
        data: notes != null ? {'notes': notes} : {},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectTaskProof(String submissionId, String reasonCode, String note) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.rejectSubmission(submissionId),
        data: {
          'reasonCode': reasonCode,
          'note': note,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
