import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import 'crashlytics_service.dart';

class ApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;

  static void _reportApiError({
    required String endpoint,
    required String method,
    int? statusCode,
    required dynamic error,
    StackTrace? stackTrace,
    String? responseBody,
  }) {
    CrashlyticsService.recordApiError(
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
      error: error,
      stackTrace: stackTrace,
      responseSnippet: responseBody,
    );
  }

  static Future<String?> getToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        return await currentUser.getIdToken().timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> saveUserData({required String email, required String uid, String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_id', uid);
    if (name != null) await prefs.setString('user_name', name);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('user_email');
    String? uid = prefs.getString('user_id');
    String? token = prefs.getString('auth_token');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          email = currentUser.email;
        }
        uid = currentUser.uid;
        try {
          final idToken = await currentUser.getIdToken().timeout(const Duration(seconds: 4));
          if (idToken != null && idToken.isNotEmpty) {
            token = idToken;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback worker identifier for backend UserSyncService
    email ??= 'worker_app_user@taskpost.com';
    uid ??= 'worker_device_user';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-user-email': email,
      'x-user-id': uid,
      'x-user-role': 'WORKER',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Auth APIs ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    debugPrint('[API] Logging in: $url');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 15));
    debugPrint('[API] Login response: ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['token'] != null) {
        await saveToken(data['token'].toString());
      }
      return data;
    }
    throw Exception('Login failed: ${response.statusCode} - ${response.body}');
  }

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    debugPrint('[API] Google login: $url');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'role': 'WORKER'}),
    ).timeout(const Duration(seconds: 15));
    debugPrint('[API] Google login response: ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['token'] != null) {
        await saveToken(data['token'].toString());
      }
      return data;
    }
    throw Exception('Google Login failed: ${response.statusCode} - ${response.body}');
  }

  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': name,
        'role': 'WORKER',
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['token'] != null) {
        await saveToken(data['token'].toString());
      }
      return data;
    }
    throw Exception('Register failed: ${response.statusCode} - ${response.body}');
  }

  // --- Worker Task APIs ---
  static Future<List<dynamic>> getAvailableTasks() async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/worker/tasks/available');
    debugPrint('[API] GET available tasks: $url headers: $headers');
    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      debugPrint('[API] Available tasks status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('tasks') && data['tasks'] is List) {
          return data['tasks'];
        }
        return [];
      }
      debugPrint('[API ERROR] ${response.statusCode} - ${response.body}');
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('[API EXCEPTION getAvailableTasks] $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getMyTasks(String stage) async {
    final headers = await _headers();
    final normalizedStage = stage.replaceAll('_', '-');
    final url = Uri.parse('$baseUrl/worker/tasks/$normalizedStage');
    debugPrint('[API] GET my tasks ($stage): $url');
    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      debugPrint('[API] My tasks response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('tasks') && data['tasks'] is List) {
          return data['tasks'];
        }
        return [];
      }
      throw Exception('Failed to load tasks for stage "$stage" (${response.statusCode})');
    } catch (e) {
      debugPrint('[API EXCEPTION getMyTasks] $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> acceptTask(String taskId) async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/worker/tasks/$taskId/accept');
    final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Accept task failed (${response.statusCode}): ${response.body}');
  }

  static Future<Map<String, dynamic>> startTask(String taskId) async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/worker/tasks/$taskId/start');
    final response = await http.post(url, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Start task failed (${response.statusCode}): ${response.body}');
  }

  static Future<Map<String, dynamic>> submitTaskProof(String taskId, Map<String, dynamic> proofData) async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/worker/tasks/$taskId/submit');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(proofData),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception('Submit proof failed (${response.statusCode}): ${response.body}');
  }

  static Future<Map<String, dynamic>> uploadFile(String filePath) async {
    final headers = await _headers();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/files/upload'));
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // --- Worker Profile & KYC APIs ---
  static Future<Map<String, dynamic>> submitKycBankDetails(Map<String, dynamic> data) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/worker/kyc'),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final headers = await _headers();
    final nestedData = {
      'profile': data,
    };
    final response = await http.patch(
      Uri.parse('$baseUrl/worker/profile'),
      headers: headers,
      body: jsonEncode(nestedData),
    ).timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<void> updateDeviceToken(String token) async {
    try {
      final headers = await _headers();
      await http.put(
        Uri.parse('$baseUrl/worker/notifications/device-token'),
        headers: headers,
        body: jsonEncode({'deviceToken': token}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // --- Worker Dashboard & Earnings APIs ---
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/dashboard'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/earnings'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> getWallet() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/earnings/wallet'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> pingPresence() async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('$baseUrl/worker/availability/ping'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {};
  }

  static Future<Map<String, dynamic>> requestPayout(double amount, String paymentMethodId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/worker/earnings/withdraw'),
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'paymentMethodId': paymentMethodId,
      }),
    ).timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getScore() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl/worker/score'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load score (${response.statusCode})');
  }
}

