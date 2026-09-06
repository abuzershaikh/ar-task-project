import 'package:flutter/foundation.dart';

class AppConstants {
  // API Configuration
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      // In web browser, use current origin so calls go through Nginx reverse proxy (/api/v1/)
      if (origin.isNotEmpty && !origin.contains('localhost:')) {
        return '$origin/api/v1';
      }
    }
    return 'http://65.20.77.112:3000/api/v1';
  }
  static const String apiVersion = 'v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // Storage Keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String businessName = 'business_name';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Campaign Constants
  static const int minQuantity = 10;
  static const int maxQuantity = 10000;
  static const int minAcceptHours = 24;
  static const int maxAcceptHours = 168;
  static const int minCompleteHours = 24;
  static const int maxCompleteHours = 720;
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocFormats = ['pdf', 'doc', 'docx'];
  
  // Payment
  static const String currency = 'INR';
  
  // App Info
  static const String appName = 'Marketing Pro';
  static const String supportEmail = 'support@taskpost.com';
  static const String supportPhone = '+91-XXXXXXXXXX';
  
  // Feature Flags
  static const bool enableRating = true;
  static const bool enableAnalytics = true;
  static const bool enableNotifications = true;
}