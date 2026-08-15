import '../../../../core/network/dio_client.dart';
import '../models/campaign_detail_model.dart';

abstract class CampaignRemoteDataSource {
  Future<List<CampaignDetailModel>> getCampaigns({
    String? status,
    int page = 1,
    int limit = 20,
  });

  Future<CampaignDetailModel> getCampaignDetail(String id);

  Future<List<dynamic>> getCampaignTasks(
    String id, {
    String? status,
    int page = 1,
    int limit = 20,
  });

  Future<List<dynamic>> getCampaignReviews(
    String id, {
    int page = 1,
    int limit = 20,
  });

  Future<List<dynamic>> getCampaignActivity(String id);

  Future<Map<String, dynamic>> getCampaignAnalytics(String id);

  Future<CampaignDetailModel> pauseCampaign(String id);

  Future<CampaignDetailModel> resumeCampaign(String id);

  Future<void> cancelCampaign(String id);

  Future<CampaignDetailModel> createCampaign({
    required String serviceId,
    required String name,
    required int quantity,
    required String instructions,
    required List<String> proofRequirements,
    required int acceptWithinHours,
    required int completeWithinHours,
    required DateTime deadline,
    required String reviewMode,
  });
}

class CampaignRemoteDataSourceImpl implements CampaignRemoteDataSource {
  final DioClient client;

  CampaignRemoteDataSourceImpl(this.client);

  @override
  Future<List<CampaignDetailModel>> getCampaigns({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      '/buyer/orders',
      queryParameters: {
        if (status != null && status.toLowerCase() != 'all') 'status': status,
        'page': page,
        'limit': limit,
      },
    );

    List<dynamic> orders = [];
    if (response.data is List) {
      orders = response.data as List<dynamic>;
    } else if (response.data is Map) {
      orders = (response.data['orders'] ?? response.data['data'] ?? []) as List<dynamic>;
    }
    return orders.map((json) => CampaignDetailModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<CampaignDetailModel> getCampaignDetail(String id) async {
    final response = await client.get('/buyer/orders/$id');
    final data = Map<String, dynamic>.from(response.data['order'] ?? response.data);
    return CampaignDetailModel.fromJson(data);
  }

  @override
  Future<List<dynamic>> getCampaignTasks(
    String id, {
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      '/buyer/orders/$id/tasks',
      queryParameters: {
        if (status != null && status.toLowerCase() != 'all') 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return (response.data['tasks'] as List<dynamic>?) ?? [];
  }

  @override
  Future<List<dynamic>> getCampaignReviews(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.get(
      '/buyer/orders/$id/pending',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return (response.data['tasks'] as List<dynamic>?) ?? [];
  }

  @override
  Future<List<dynamic>> getCampaignActivity(String id) async {
    final response = await client.get('/buyer/orders/$id/activity');
    return (response.data['activity'] as List<dynamic>?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getCampaignAnalytics(String id) async {
    final response = await client.get('/buyer/orders/$id/analytics');
    return Map<String, dynamic>.from(response.data['analytics'] ?? response.data ?? {});
  }

  @override
  Future<CampaignDetailModel> pauseCampaign(String id) async {
    await client.post('/buyer/orders/$id/pause');
    return getCampaignDetail(id);
  }

  @override
  Future<CampaignDetailModel> resumeCampaign(String id) async {
    await client.post('/buyer/orders/$id/resume');
    return getCampaignDetail(id);
  }

  @override
  Future<void> cancelCampaign(String id) async {
    await client.post('/buyer/orders/$id/cancel');
  }

  @override
  Future<CampaignDetailModel> createCampaign({
    required String serviceId,
    required String name,
    required int quantity,
    required String instructions,
    required List<String> proofRequirements,
    required int acceptWithinHours,
    required int completeWithinHours,
    required DateTime deadline,
    required String reviewMode,
  }) async {
    final response = await client.post(
      '/buyer/orders',
      data: {
        'serviceId': serviceId,
        'title': name,
        'quantity': quantity,
        'description': instructions,
        'requirements': proofRequirements,
        'timeToAcceptHours': acceptWithinHours,
        'timeToCompleteHours': completeWithinHours,
        'campaignExpiryDate': deadline.toIso8601String(),
        'reviewMode': reviewMode,
      },
    );

    final data = Map<String, dynamic>.from(response.data['order'] ?? response.data);
    return CampaignDetailModel.fromJson(data);
  }
}
