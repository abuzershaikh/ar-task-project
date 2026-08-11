class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String splash = '/';
  
  // Dashboard
  static const String dashboard = '/dashboard';
  
  // Workers
  static const String workers = '/workers';
  static const String workerDetail = '/workers/:id';
  static const String workerScore = '/workers/:id/score';
  
  // Buyers
  static const String buyers = '/buyers';
  static const String buyerDetail = '/buyers/:id';
  
  // Orders
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  
  // Services
  static const String services = '/services';
  static const String serviceDetail = '/services/:id';
  static const String servicePricing = '/services/:id/pricing';
  
  // Reviews
  static const String reviews = '/reviews';
  static const String reviewDetail = '/reviews/:id';
  
  // KYC
  static const String kyc = '/kyc';
  static const String kycDetail = '/kyc/:id';
  
  // Payouts
  static const String payouts = '/payouts';
  static const String payoutDetail = '/payouts/:id';
  
  // Analytics
  static const String analytics = '/analytics';
  
  // Settings
  static const String settings = '/settings';
  static const String matchingConfig = '/settings/matching';
  static const String systemSettings = '/settings/system';
  
  // Audit
  static const String auditLogs = '/audit';
  
  // Risk
  static const String risk = '/risk';
}
