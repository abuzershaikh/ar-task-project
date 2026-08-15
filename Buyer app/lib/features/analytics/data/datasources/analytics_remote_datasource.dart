import '../../../../core/network/dio_client.dart';
import '../models/analytics_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsModel> getAnalytics();
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final DioClient client;

  AnalyticsRemoteDataSourceImpl(this.client);

  @override
  Future<AnalyticsModel> getAnalytics() async {
    final response = await client.get('/buyer/dashboard');
    final data = Map<String, dynamic>.from(response.data['analytics'] ?? response.data['dashboard'] ?? response.data);
    return AnalyticsModel.fromJson(data);
  }
}
