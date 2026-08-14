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
      if (response.statusCode == 200) {
        return response.data['dashboard'] as Map<String, dynamic>;
      } else {
        throw ServerException('Failed to load dashboard data');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getEarningsDashboard() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.dashboardEarnings);
      if (response.statusCode == 200) {
        return response.data['financialSummary'] as Map<String, dynamic>;
      } else {
        throw ServerException('Failed to load earnings data');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
