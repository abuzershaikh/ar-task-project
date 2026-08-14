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
  /// Get pending submissions for review
  /// Query params: ?status=pending|approved|rejected&page=1&limit=20
  static const String submissions = '$buyer/reviews/pending';
  
  /// Get submission detail with proof
  static String submissionDetail(String id) => '$buyer/reviews/$id';
  
  /// Approve submission
  static String approveSubmission(String id) => '$buyer/reviews/$id/approve';
  
  /// Reject submission
  static String rejectSubmission(String id) => '$buyer/reviews/$id/reject';
  
  /// Request changes to submission
  static String requestChanges(String id) => '$buyer/reviews/$id/request-changes';
  
  /// Rate worker after approval
  static String rateWorker(String submissionId) => '$buyer/reviews/$submissionId/rate';
  
  // ============ ANALYTICS ============
  /// Get overall analytics
  static const String analytics = '$buyer/analytics';
  
  /// Get analytics overview
  static const String analyticsOverview = '$buyer/analytics/overview';
  
  /// Get completion trends
  static const String completionTrends = '$buyer/analytics/trends/completion';
  
  /// Get performance metrics
  static const String performanceMetrics = '$buyer/analytics/performance';
  
  /// Get spending analysis
  static const String spendingAnalysis = '$buyer/analytics/spending';
  
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
  /// Get invoice list
  /// Query params: ?page=1&limit=20
  static const String invoices = '$buyer/invoices';
  
  /// Get invoice detail
  static String invoiceDetail(String id) => '$buyer/invoices/$id';
  
  /// Download invoice PDF
  static String downloadInvoice(String id) => '$buyer/invoices/$id/download';
  
  // ============ NOTIFICATIONS ============
  /// Get notifications
  /// Query params: ?type=all|campaign|review|payment|system&page=1&limit=20
  static const String notifications = '$buyer/notifications';
  
  /// Mark notification as read
  static String markNotificationRead(String id) => '$buyer/notifications/$id/read';
  
  /// Mark all notifications as read
  static const String markAllNotificationsRead = '$buyer/notifications/mark-all-read';
  
  /// Get unread notification count
  static const String unreadCount = '$buyer/notifications/unread-count';
  
  // ============ PROFILE ============
  /// Get buyer profile
  static const String profile = '$buyer/profile';
  
  /// Update profile
  static const String updateProfile = '$buyer/profile';
  
  /// Get business profile
  static const String businessProfile = '$buyer/business-profile';
  
  /// Update business profile
  static const String updateBusinessProfile = '$buyer/business-profile';
  
  /// Upload profile image
  static const String uploadProfileImage = '$buyer/profile/upload-image';
  
  /// Change password
  static const String changePassword = '$buyer/profile/change-password';
  
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
