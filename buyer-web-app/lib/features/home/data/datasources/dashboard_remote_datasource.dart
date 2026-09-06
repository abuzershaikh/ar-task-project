import '../../../../core/network/dio_client.dart';
import '../models/dashboard_data_model.dart';
import '../models/campaign_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardDataModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient client;

  DashboardRemoteDataSourceImpl(this.client);

  @override
  Future<DashboardDataModel> getDashboardData() async {
    final response = await client.get('/buyer/dashboard');
    if (response.statusCode == 200 && response.data != null) {
      final dataMap = response.data['dashboard'] ?? response.data['data'] ?? response.data;
      return DashboardDataModel.fromJson(dataMap as Map<String, dynamic>);
    }
    throw Exception('Failed to load dashboard data');
  }
}
