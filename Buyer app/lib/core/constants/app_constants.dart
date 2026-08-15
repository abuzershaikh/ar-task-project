class AppConstants {
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://95.179.178.6:3000/api/v1',
  );
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