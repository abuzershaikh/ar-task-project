/// Admin API Endpoints v1.0
/// Aligned with API_CONTRACT_ADMIN_V1.md
class ApiEndpoints {
  // ==================== Auth ====================
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/me';
  
  // ==================== Dashboard ====================
  static const String dashboard = '/admin/dashboard';
  static const String dashboardOrders = '/admin/dashboard/orders';
  static const String dashboardTasks = '/admin/dashboard/tasks';
  static const String dashboardWorkers = '/admin/dashboard/workers';
  static const String dashboardBuyers = '/admin/dashboard/buyers';
  static const String dashboardEarnings = '/admin/dashboard/earnings';
  static const String dashboardPayouts = '/admin/dashboard/payouts';
  
  // ==================== Workers ====================
  static const String workers = '/admin/workers';
  static String workerById(String id) => '/admin/workers/$id';
  static String workerScoreBreakdown(String id) => '/admin/workers/$id/score-breakdown';
  static String workerTasks(String id) => '/admin/workers/$id/tasks';
  static String workerEarnings(String id) => '/admin/workers/$id/earnings';
  static String workerKyc(String id) => '/admin/workers/$id/kyc';
  static String workerSuspend(String id) => '/admin/workers/$id/suspend';
  static String workerBan(String id) => '/admin/workers/$id/ban';
  static String workerActivate(String id) => '/admin/workers/$id/activate';
  
  // ==================== Buyers ====================
  static const String buyers = '/admin/buyers';
  static String buyerById(String id) => '/admin/buyers/$id';
  static String buyerBalanceLedger(String id) => '/admin/buyers/$id/balance-ledger';
  static String buyerOrders(String id) => '/admin/buyers/$id/orders';
  static String buyerApiKeys(String id) => '/admin/buyers/$id/api-keys';
  static String buyerApiKeyRevoke(String buyerId, String keyId) => 
      '/admin/buyers/$buyerId/api-keys/$keyId';
  static String buyerWebhooks(String id) => '/admin/buyers/$id/webhooks';
  static String buyerBalanceAdjust(String id) => '/admin/buyers/$id/balance/adjust';
  
  // ==================== Orders / Campaigns ====================
  static const String orders = '/admin/orders';
  static String orderById(String id) => '/admin/orders/$id';
  static String orderTasks(String id) => '/admin/orders/$id/tasks';
  static String orderProgress(String id) => '/admin/orders/$id/progress';
  static String orderExtend(String id) => '/admin/orders/$id/extend';
  static String orderPause(String id) => '/admin/orders/$id/pause';
  static String orderResume(String id) => '/admin/orders/$id/resume';
  static String orderCancel(String id) => '/admin/orders/$id/cancel';
  
  // ==================== Services & Pricing ====================
  static const String services = '/admin/services';
  static String serviceById(String id) => '/admin/services/$id';
  static String servicePricingHistory(String id) => '/admin/services/$id/pricing-history';
  static String serviceActivate(String id) => '/admin/services/$id/activate';
  static String serviceDeactivate(String id) => '/admin/services/$id/deactivate';
  
  // ==================== Matching Engine ====================
  static const String matchingConfig = '/admin/matching/config';
  static const String matchingConfigHistory = '/admin/matching/config/history';
  static const String matchingPreview = '/admin/matching/preview';
  static String matchingDecisions(String taskId) => '/admin/matching/decisions/$taskId';
  
  // ==================== Reviews ====================
  static const String reviews = '/admin/reviews';
  static String reviewById(String id) => '/admin/reviews/$id';
  static String reviewApprove(String id) => '/admin/reviews/$id/approve';
  static String reviewReject(String id) => '/admin/reviews/$id/reject';
  static String reviewRequestChanges(String id) => '/admin/reviews/$id/request-changes';
  
  // ==================== KYC ====================
  static const String kyc = '/admin/kyc';
  static String kycById(String id) => '/admin/kyc/$id';
  static String kycVerify(String id) => '/admin/kyc/$id/verify';
  static String kycReject(String id) => '/admin/kyc/$id/reject';
  
  // ==================== Payouts ====================
  static const String payouts = '/admin/payouts';
  static String payoutById(String id) => '/admin/payouts/$id';
  static String payoutProcess(String id) => '/admin/payouts/$id/process';
  static String payoutReject(String id) => '/admin/payouts/$id/reject';
  
  // ==================== Analytics ====================
  static const String analyticsOverview = '/admin/analytics/overview';
  static const String analyticsRevenue = '/admin/analytics/revenue';
  static const String analyticsTasks = '/admin/analytics/tasks';
  
  // ==================== Risk & Fraud ====================
  static const String riskDashboard = '/admin/risk/dashboard';
  static const String riskWorkers = '/admin/risk/workers';
  
  // ==================== System Settings ====================
  static const String settings = '/admin/settings';
  
  // ==================== Audit Logs ====================
  static const String auditLogs = '/admin/audit-logs';
  
  // ==================== Notifications ====================
  static const String notifications = '/admin/notifications';
  static String notificationMarkRead(String id) => '/admin/notifications/$id/read';
}
