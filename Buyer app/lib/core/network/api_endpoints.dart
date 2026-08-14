/// API Endpoints for Buyer App
/// 
/// Base URL configured in app_constants.dart
/// All endpoints use /api/v1 prefix
class ApiEndpoints {
  // Base paths
  static const String auth = '/auth';
  static const String buyer = '/buyer';
  
  // ============ AUTHENTICATION ============
  static const String login = '$auth/login';
  static const String logout = '$auth/logout';
  static const String refresh = '$auth/refresh';
  static const String register = '$auth/register';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  
  // ============ DASHBOARD ============
  static const String dashboard = '$buyer/dashboard';
  static const String stats = '$buyer/stats';
  
  // ============ WALLET & BALANCE (NEW) ============
  /// Get current wallet balance (Available + Reserved)
  static const String walletBalance = '$buyer/wallet/balance';
  
  /// Get transaction history with filters
  /// Query params: ?type=all|credit|debit|reserved&page=1&limit=20
  static const String transactions = '$buyer/wallet/transactions';
  
  /// Get transaction detail by ID
  static String transactionDetail(String id) => '$buyer/wallet/transactions/$id';
  
  /// Initiate add balance flow
  static const String addBalance = '$buyer/wallet/add-balance';
  
  /// Verify balance payment
  static const String verifyBalancePayment = '$buyer/wallet/verify-payment';
  
  // ============ CAMPAIGNS (ORDERS) ============
  /// List all campaigns with filters
  /// Query params: ?status=active|paused|completed&page=1&limit=20
  static const String campaigns = '$buyer/orders';
  
  /// Create new campaign
  static const String createCampaign = '$buyer/orders';
  
  /// Get campaign detail with comprehensive info
  /// Returns: progress, tasks, reviews, activity, analytics
  static String campaignDetail(String id) => '$buyer/orders/$id';
  
  /// Get campaign overview tab data
  static String campaignOverview(String id) => '$buyer/orders/$id/overview';
  
  /// Get campaign tasks with filters
  /// Query params: ?status=pending|working|submitted|approved|rejected
  static String campaignTasks(String id) => '$buyer/orders/$id/tasks';
  
  /// Get campaign pending reviews
  static String campaignReviews(String id) => '$buyer/orders/$id/reviews';
  
  /// Get campaign activity timeline
  static String campaignActivity(String id) => '$buyer/orders/$id/activity';
  
  /// Get campaign-specific analytics
  static String campaignAnalytics(String id) => '$buyer/orders/$id/analytics';
  
  /// Pause campaign
  static String pauseCampaign(String id) => '$buyer/orders/$id/pause';
  
  /// Resume campaign
  static String resumeCampaign(String id) => '$buyer/orders/$id/resume';
  
  /// Extend campaign deadline
  static String extendCampaign(String id) => '$buyer/orders/$id/extend';
  
  /// Cancel campaign
  static String cancelCampaign(String id) => '$buyer/orders/$id/cancel';
  
  /// Get campaign invoice
  static String campaignInvoice(String id) => '$buyer/orders/$id/invoice';
  
  // ============ SERVICES ============
  /// List all available services
  static const String services = '$buyer/services';
  
  /// Get service detail
  static String serviceDetail(String id) => '$buyer/services/$id';
  
  /// Get service pricing
  static String servicePricing(String id) => '$buyer/services/$id/pricing';
  
  // ============ REVIEWS (SUBMISSIONS) ============
  static const String submissions = '$buyer/reviews/pending';
  static String submissionDetail(String id) => '$buyer/reviews/$id';
  static String approveSubmission(String id) => '$buyer/reviews/$id/approve';
  static String rejectSubmission(String id) => '$buyer/reviews/$id/reject';
  static String requestChanges(String id) => '$buyer/reviews/$id/request-changes';
  
  // ============ RATINGS ============
  static String rateWorker(String taskId) => '$buyer/tasks/$taskId/rating';
  
  // ============ ANALYTICS ============
  static const String analyticsOverview = '$buyer/analytics/overview';
  
  // ============ PAYMENTS ============
  /// Initiate payment for campaign
  static const String initiatePayment = '$buyer/payments/initiate';
  
  /// Verify payment callback
  static const String verifyPayment = '$buyer/payments/verify';
  
  /// Get payment history
  /// Query params: ?status=all|successful|pending|failed&page=1&limit=20
  static const String payments = '$buyer/payments';
  
  /// Get payment detail
  static String paymentDetail(String id) => '$buyer/payments/$id';
  
  // ============ INVOICES ============
  static const String invoices = '$buyer/invoices';
  
  // ============ NOTIFICATIONS ============
  static const String notifications = '$buyer/notifications';
  static String markNotificationRead(String id) => '$buyer/notifications/$id/read';
  
  // ============ PROFILE ============
  static const String profile = '$buyer/profile';
  static const String updateProfile = '$buyer/profile';
  
  // ============ SUPPORT ============
  /// Get help articles
  static const String helpArticles = '$buyer/support/articles';
  
  /// Search help articles
  static const String searchHelp = '$buyer/support/search';
  
  /// Submit support ticket
  static const String submitTicket = '$buyer/support/tickets';
  
  /// Get support tickets
  static const String tickets = '$buyer/support/tickets';
  
  /// Get ticket detail
  static String ticketDetail(String id) => '$buyer/support/tickets/$id';
  
  // ============ SETTINGS ============
  /// Get notification preferences
  static const String notificationSettings = '$buyer/settings/notifications';
  
  /// Update notification preferences
  static const String updateNotificationSettings = '$buyer/settings/notifications';
  
  /// Get app settings
  static const String appSettings = '$buyer/settings';
}
