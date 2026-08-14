class AppConstants {
  // API
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://95.179.178.6:3000');
  static const String apiPrefix = '/api/v1';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Admin Roles
  static const String superAdmin = 'SUPER_ADMIN';
  static const String admin = 'ADMIN';
  static const String operations = 'OPERATIONS';
  static const String finance = 'FINANCE';
  static const String kycReviewer = 'KYC_REVIEWER';
  static const String support = 'SUPPORT';
}
