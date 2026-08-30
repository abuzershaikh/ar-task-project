import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';

class DashboardRepository {
  final DioClient _dioClient;

  DashboardRepository(this._dioClient);

  Future<Map<String, dynamic>> getMasterDashboard() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.dashboard);
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['dashboard'] ?? response.data;
        return Map<String, dynamic>.from(raw as Map);
      } else {
        throw ServerException('Failed to load dashboard data');
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getEarningsDashboard() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.dashboardEarnings);
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['financialSummary'] ?? response.data;
        return Map<String, dynamic>.from(raw as Map);
      } else {
        throw ServerException('Failed to load earnings data');
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
