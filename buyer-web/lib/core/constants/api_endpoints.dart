class ApiEndpoints {
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  
  // Buyer Dashboard
  static const String dashboard = '/buyer/dashboard';
  
  // Orders (Campaigns from buyer perspective)
  static const String orders = '/buyer/orders';
  static String orderDetail(String orderId) => '/buyer/orders/$orderId';
  static String orderAnalytics(String orderId) => '/buyer/orders/$orderId/analytics';
  static String orderProgress(String orderId) => '/buyer/orders/$orderId/progress';
  static const String createOrder = '/buyer/orders';
  static String pauseOrder(String orderId) => '/buyer/orders/$orderId/pause';
  static String resumeOrder(String orderId) => '/buyer/orders/$orderId/resume';
  static String cancelOrder(String orderId) => '/buyer/orders/$orderId/cancel';
  
  // Services (Task Types)
  static const String services = '/services';
  static String serviceDetail(String serviceId) => '/services/$serviceId';
  static const String serviceCategories = '/services/categories';
  
  // Reviews & Submissions
  static const String submissions = '/buyer/submissions';
  static String submissionDetail(String submissionId) => '/buyer/submissions/$submissionId';
  static String approveSubmission(String submissionId) => '/buyer/submissions/$submissionId/approve';
  static String rejectSubmission(String submissionId) => '/buyer/submissions/$submissionId/reject';
  static String requestChanges(String submissionId) => '/buyer/submissions/$submissionId/request-changes';
  
  // Ratings
  static const String ratings = '/buyer/ratings';
  static String rateWorker(String taskId) => '/buyer/ratings/task/$taskId';
  
  // Payments
  static const String payments = '/buyer/payments';
  static String paymentDetail(String paymentId) => '/buyer/payments/$paymentId';
  static const String initiatePayment = '/buyer/payments/initiate';
  static const String verifyPayment = '/buyer/payments/verify';
  static const String paymentMethods = '/buyer/payments/methods';
  
  // Invoices
  static const String invoices = '/buyer/invoices';
  static String invoiceDetail(String invoiceId) => '/buyer/invoices/$invoiceId';
  static String downloadInvoice(String invoiceId) => '/buyer/invoices/$invoiceId/download';
  
  // Analytics
  static const String analytics = '/buyer/analytics';
  static const String analyticsOverview = '/buyer/analytics/overview';
  static String campaignAnalytics(String orderId) => '/buyer/analytics/campaign/$orderId';
  static const String performanceMetrics = '/buyer/analytics/performance';
  
  // Notifications
  static const String notifications = '/buyer/notifications';
  static String markNotificationRead(String notificationId) => '/buyer/notifications/$notificationId/read';
  static const String markAllNotificationsRead = '/buyer/notifications/read-all';
  static const String notificationSettings = '/buyer/notifications/settings';
  
  // Profile
  static const String profile = '/buyer/profile';
  static const String updateProfile = '/buyer/profile/update';
  static const String businessProfile = '/buyer/profile/business';
  static const String updateBusinessProfile = '/buyer/profile/business/update';
  static const String changePassword = '/buyer/profile/change-password';
  
  // File Upload
  static const String uploadFile = '/files/upload';
  static String getFile(String fileId) => '/files/$fileId';
  
  // Support
  static const String supportTickets = '/buyer/support/tickets';
  static const String createSupportTicket = '/buyer/support/tickets/create';
  static String supportTicketDetail(String ticketId) => '/buyer/support/tickets/$ticketId';
  static const String faqs = '/support/faqs';
  
  // Settings
  static const String settings = '/buyer/settings';
  static const String updateSettings = '/buyer/settings/update';
}
