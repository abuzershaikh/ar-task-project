import '../../../core/di/injection.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../models/tutorial_item_model.dart';

class BuyerTutorialsService {
  final DioClient _dioClient;

  BuyerTutorialsService({DioClient? dioClient})
      : _dioClient = dioClient ?? getIt<DioClient>();

  Future<List<TutorialItemModel>> getTutorials({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null && category != 'All' && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _dioClient.get(
      ApiEndpoints.buyerTutorials,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data != null && data['tutorials'] is List) {
      return (data['tutorials'] as List)
          .map((item) => TutorialItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.buyerTutorialCategories);
      final data = response.data;
      if (data != null && data['categories'] is List) {
        return List<String>.from(data['categories']);
      }
    } catch (_) {}
    return ['All'];
  }

  Future<void> recordView(String tutorialId) async {
    try {
      await _dioClient.post('/buyer/tutorials/$tutorialId/view');
    } catch (_) {}
  }
}
