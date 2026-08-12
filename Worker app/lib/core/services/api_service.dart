import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL: 10.0.2.2 for Android Emulator, local IP for physical Android device
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://95.179.178.6:3000/api/v1',
  );

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth APIs ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'role': 'WORKER'}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': name,
        'role': 'WORKER',
      }),
    );
    return jsonDecode(response.body);
  }

  // --- Worker Task APIs ---
  static Future<List<dynamic>> getAvailableTasks() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl/worker/tasks/available'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['tasks'] ?? []);
    }
    return [];
  }

  static Future<List<dynamic>> getMyTasks(String stage) async {
    final headers = await _headers();
    // Normalize stage string to match NestJS endpoints
    final normalizedStage = stage.replaceAll('_', '-');
    final response = await http.get(
      Uri.parse('$baseUrl/worker/tasks/$normalizedStage'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : (data['tasks'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>> acceptTask(String taskId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/worker/tasks/$taskId/accept'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> startTask(String taskId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/worker/tasks/$taskId/start'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> submitTaskProof(String taskId, Map<String, dynamic> proofData) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$baseUrl/worker/tasks/$taskId/submit'),
      headers: headers,
      body: jsonEncode(proofData),
    );
    return jsonDecode(response.body);
  }

  // --- Worker Dashboard & Earnings APIs ---
  static Future<Map<String, dynamic>> getDashboard() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl/worker/dashboard'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {};
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$baseUrl/worker/earnings'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
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
    );
    return jsonDecode(response.body);
  }
}
