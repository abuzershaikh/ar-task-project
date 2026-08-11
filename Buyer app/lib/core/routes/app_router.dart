import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/campaigns/presentation/pages/campaigns_page.dart';
import '../../features/campaigns/presentation/pages/campaign_detail_page.dart';
import '../../features/campaigns/presentation/pages/create_campaign_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/services/presentation/pages/service_detail_page.dart';
import '../../features/reviews/presentation/pages/reviews_page.dart';
import '../../features/reviews/presentation/pages/review_detail_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/analytics/presentation/pages/campaign_analytics_page.dart';
import '../../features/payments/presentation/pages/payments_page.dart';
import '../../features/payments/presentation/pages/payment_detail_page.dart';
import '../../features/payments/presentation/pages/checkout_page.dart';
import '../../features/invoices/presentation/pages/invoices_page.dart';
import '../../features/invoices/presentation/pages/invoice_detail_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/business_profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/support/presentation/pages/help_center_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/presentation/pages/splash_page.dart';
import '../../shared/presentation/pages/main_navigation_page.dart';

class AppRouter {
  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String mainNavigation = '/main';
  static const String home = '/home';
  
  // Services
  static const String services = '/services';
  static const String serviceDetail = '/service-detail';
  
  // Campaigns
  static const String campaigns = '/campaigns';
  static const String campaignDetail = '/campaign-detail';
  static const String createCampaign = '/create-campaign';
  
  // Reviews
  static const String reviews = '/reviews';
  static const String reviewDetail = '/review-detail';
  
  // Analytics
  static const String analytics = '/analytics';
  static const String campaignAnalytics = '/campaign-analytics';
  
  // Payments
  static const String payments = '/payments';
  static const String paymentDetail = '/payment-detail';
  static const String checkout = '/checkout';
  
  // Invoices
  static const String invoices = '/invoices';
  static const String invoiceDetail = '/invoice-detail';
  
  // Notifications
  static const String notifications = '/notifications';
  
  // Profile
  static const String profile = '/profile';
  static const String businessProfile = '/business-profile';
  static const String editProfile = '/edit-profile';
  
  // Support
  static const String support = '/support';
  static const String helpCenter = '/help-center';
  
  // Settings
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      
      case mainNavigation:
        return MaterialPageRoute(builder: (_) => const MainNavigationPage());
      
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      
      // Services
      case services:
        return MaterialPageRoute(builder: (_) => const ServicesPage());
      
      case serviceDetail:
        final serviceId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ServiceDetailPage(serviceId: serviceId),
        );
      
      // Campaigns
      case campaigns:
        return MaterialPageRoute(builder: (_) => const CampaignsPage());
      
      case campaignDetail:
        final campaignId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CampaignDetailPage(campaignId: campaignId),
        );
      
      case createCampaign:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateCampaignPage(serviceId: args?['serviceId']),
        );
      
      // Reviews
      case reviews:
        return MaterialPageRoute(builder: (_) => const ReviewsPage());
      
      case reviewDetail:
        final submissionId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ReviewDetailPage(submissionId: submissionId),
        );
      
      // Analytics
      case analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsPage());
      
      case campaignAnalytics:
        final campaignId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CampaignAnalyticsPage(campaignId: campaignId),
        );
      
      // Payments
      case payments:
        return MaterialPageRoute(builder: (_) => const PaymentsPage());
      
      case paymentDetail:
        final paymentId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PaymentDetailPage(paymentId: paymentId),
        );
      
      case checkout:
        final checkoutData = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CheckoutPage(checkoutData: checkoutData),
        );
      
      // Invoices
      case invoices:
        return MaterialPageRoute(builder: (_) => const InvoicesPage());
      
      case invoiceDetail:
        final invoiceId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailPage(invoiceId: invoiceId),
        );
      
      // Notifications
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());
      
      // Profile
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      
      case businessProfile:
        return MaterialPageRoute(builder: (_) => const BusinessProfilePage());
      
      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      
      // Support
      case support:
        return MaterialPageRoute(builder: (_) => const SupportPage());
      
      case helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterPage());
      
      // Settings
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${routeSettings.name} not found'),
            ),
          ),
        );
    }
  }
}
