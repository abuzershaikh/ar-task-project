import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../models/worker_tutorial_item.dart';

/// Service for fetching tutorials for the Worker audience.
/// Uses the same http-based pattern as the rest of the Worker app.
class WorkerTutorialsService {
  static String get _baseUrl => AppConstants.apiBaseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch tutorials targeted at workers, with optional category / search.
  static Future<List<WorkerTutorialItem>> getTutorials({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category != 'All' && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$_baseUrl/worker/tutorials')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final headers = await _authHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data != null && data['tutorials'] is List) {
        return (data['tutorials'] as List)
            .map((item) =>
                WorkerTutorialItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }
    return [];
  }

  /// Fetch available categories for filter chips.
  static Future<List<String>> getCategories() async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$_baseUrl/worker/tutorials/categories');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['categories'] is List) {
          return List<String>.from(data['categories']);
        }
      }
    } catch (_) {}
    return ['All'];
  }

  /// Record a view (fire-and-forget).
  static Future<void> recordView(String tutorialId) async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('$_baseUrl/worker/tutorials/$tutorialId/view'),
        headers: headers,
      );
    } catch (_) {}
  }
}
