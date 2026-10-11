import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_tutorial_model.dart';

class AdminTutorialsService {
  final DioClient _dioClient;

  AdminTutorialsService({DioClient? dioClient})
      : _dioClient = dioClient ?? getIt<DioClient>();

  Future<List<AdminTutorialModel>> getTutorials({
    String? targetAudience,
    String? category,
    String? search,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};
    if (targetAudience != null && targetAudience != 'all') {
      queryParams['targetAudience'] = targetAudience;
    }
    if (category != null && category != 'All' && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive;
    }

    final response = await _dioClient.get(
      '/admin/tutorials',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data != null && data['tutorials'] is List) {
      return (data['tutorials'] as List)
          .map((item) => AdminTutorialModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<List<String>> getCategories({String? targetAudience}) async {
    final queryParams = <String, dynamic>{};
    if (targetAudience != null && targetAudience != 'all') {
      queryParams['targetAudience'] = targetAudience;
    }

    final response = await _dioClient.get(
      '/admin/tutorials/categories',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data != null && data['categories'] is List) {
      return List<String>.from(data['categories']);
    }
    return ['All'];
  }

  Future<AdminTutorialModel> createTutorial({
    required String title,
    String? description,
    required String videoUrl,
    String? thumbnailUrl,
    required String category,
    String? tags,
    required String targetAudience,
    required int displayOrder,
    String? duration,
    bool isActive = true,
  }) async {
    final payload = {
      'title': title.trim(),
      'description': description?.trim(),
      'videoUrl': videoUrl.trim(),
      if (thumbnailUrl != null && thumbnailUrl.trim().isNotEmpty)
        'thumbnailUrl': thumbnailUrl.trim(),
      'category': category.trim(),
      'tags': tags?.trim(),
      'targetAudience': targetAudience.trim().toLowerCase(),
      'displayOrder': displayOrder,
      if (duration != null && duration.trim().isNotEmpty)
        'duration': duration.trim(),
      'isActive': isActive,
    };

    final response = await _dioClient.post('/admin/tutorials', data: payload);
    final data = response.data;
    if (data != null && data['tutorial'] != null) {
      return AdminTutorialModel.fromJson(Map<String, dynamic>.from(data['tutorial']));
    }
    throw Exception(data?['message'] ?? 'Failed to create tutorial');
  }

  Future<AdminTutorialModel> updateTutorial(
    String id, {
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    String? category,
    String? tags,
    String? targetAudience,
    int? displayOrder,
    String? duration,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (description != null) payload['description'] = description.trim();
    if (videoUrl != null) payload['videoUrl'] = videoUrl.trim();
    if (thumbnailUrl != null) payload['thumbnailUrl'] = thumbnailUrl.trim();
    if (category != null) payload['category'] = category.trim();
    if (tags != null) payload['tags'] = tags.trim();
    if (targetAudience != null) payload['targetAudience'] = targetAudience.trim().toLowerCase();
    if (displayOrder != null) payload['displayOrder'] = displayOrder;
    if (duration != null) payload['duration'] = duration.trim();
    if (isActive != null) payload['isActive'] = isActive;

    final response = await _dioClient.put('/admin/tutorials/$id', data: payload);
    final data = response.data;
    if (data != null && data['tutorial'] != null) {
      return AdminTutorialModel.fromJson(Map<String, dynamic>.from(data['tutorial']));
    }
    throw Exception(data?['message'] ?? 'Failed to update tutorial');
  }

  Future<bool> toggleStatus(String id) async {
    final response = await _dioClient.patch('/admin/tutorials/$id/toggle-status');
    final data = response.data;
    return data?['success'] == true;
  }

  Future<bool> deleteTutorial(String id) async {
    final response = await _dioClient.delete('/admin/tutorials/$id');
    final data = response.data;
    return data?['success'] == true;
  }

  Future<void> updateOrder(List<Map<String, dynamic>> items) async {
    await _dioClient.post(
      '/admin/tutorials/reorder',
      data: {'items': items},
    );
  }
}
