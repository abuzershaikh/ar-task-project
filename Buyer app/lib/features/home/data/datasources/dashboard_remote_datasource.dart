import '../../../../core/network/dio_client.dart';
import '../models/dashboard_data_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardDataModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient client;

  DashboardRemoteDataSourceImpl(this.client);

  @override
  Future<DashboardDataModel> getDashboardData() async {
    final response = await client.get('/buyer/dashboard');
    return DashboardDataModel.fromJson(response.data['data']);
  }
}
