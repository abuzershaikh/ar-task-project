/// Navigation constants for Buyer App
/// 
/// Defines the 5-tab bottom navigation structure:
/// Home | Campaigns | Reviews | Analytics | More

class NavigationConstants {
  // Bottom Navigation Tabs
  static const int homeTab = 0;
  static const int campaignsTab = 1;
  static const int reviewsTab = 2;
  static const int analyticsTab = 3;
  static const int moreTab = 4;

  // Tab Labels
  static const String homeLabel = 'Home';
  static const String campaignsLabel = 'Campaigns';
  static const String reviewsLabel = 'Reviews';
  static const String analyticsLabel = 'Analytics';
  static const String moreLabel = 'More';

  // Tab Icons
  static const String homeIcon = 'home';
  static const String campaignsIcon = 'clipboard';
  static const String reviewsIcon = 'check_circle';
  static const String analyticsIcon = 'bar_chart';
  static const String moreIcon = 'more_horiz';

  // Route Names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String mainRoute = '/main';
  static const String homeRoute = '/home';
  
  // Campaign Routes
  static const String campaignsRoute = '/campaigns';
  static const String campaignDetailRoute = '/campaign-detail';
  static const String createCampaignRoute = '/create-campaign';
  static const String createCampaignStep1Route = '/create-campaign/step1';
  static const String createCampaignStep2Route = '/create-campaign/step2';
  static const String createCampaignStep3Route = '/create-campaign/step3';
  static const String createCampaignStep4Route = '/create-campaign/step4';
  static const String createCampaignStep5Route = '/create-campaign/step5';
  static const String createCampaignStep6Route = '/create-campaign/step6';
  static const String campaignSuccessRoute = '/campaign-success';
  
  // Review Routes
  static const String reviewsRoute = '/reviews';
  static const String reviewDetailRoute = '/review-detail';
  static const String rateWorkerRoute = '/rate-worker';
  
  // Analytics Routes
  static const String analyticsRoute = '/analytics';
  static const String campaignAnalyticsRoute = '/campaign-analytics';
  
  // Wallet Routes
  static const String walletRoute = '/wallet';
  static const String addBalanceRoute = '/add-balance';
  static const String transactionHistoryRoute = '/transaction-history';
  
  // Payment Routes
  static const String paymentsRoute = '/payments';
  static const String paymentDetailRoute = '/payment-detail';
  static const String checkoutRoute = '/checkout';
  
  // Invoice Routes
  static const String invoicesRoute = '/invoices';
  static const String invoiceDetailRoute = '/invoice-detail';
  
  // Profile Routes
  static const String profileRoute = '/profile';
  static const String businessProfileRoute = '/business-profile';
  static const String editProfileRoute = '/edit-profile';
  
  // Settings Routes
  static const String settingsRoute = '/settings';
  static const String notificationsRoute = '/notifications';
  static const String supportRoute = '/support';
  static const String helpCenterRoute = '/help-center';
}
