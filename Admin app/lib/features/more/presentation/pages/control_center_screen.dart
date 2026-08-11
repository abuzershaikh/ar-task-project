import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'services_pricing_screen.dart';
import 'matching_brain_screen.dart';
import 'payouts_queue_screen.dart';
import 'kyc_queue_screen.dart';
import 'task_reviews_queue_screen.dart';
import 'audit_logs_screen.dart';

class ControlCenterScreen extends StatelessWidget {
  const ControlCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Center'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('System Management', [
            _buildMenuItem(
              context,
              Icons.settings,
              'Services & Pricing',
              'Manage service catalog and pricing',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServicesPricingScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.psychology,
              'Matching Brain',
              'View matching engine status',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MatchingBrainScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.account_balance_wallet,
              'Payouts Management',
              'Approve pending withdrawals',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PayoutsQueueScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.verified_user,
              'KYC Management',
              'Review identity verifications',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KycQueueScreen()),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSection('Operations', [
            _buildMenuItem(
              context,
              Icons.rate_review,
              'Task Reviews Queue',
              'Review pending submissions',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TaskReviewsQueueScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.currency_rupee,
              'Finance & Ledger',
              'View platform financials',
              () {},
            ),
            _buildMenuItem(
              context,
              Icons.security,
              'Risk & Fraud Control',
              'Monitor suspicious activity',
              () {},
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSection('System', [
            _buildMenuItem(
              context,
              Icons.history,
              'Audit Logs',
              'View system activity logs',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.settings_applications,
              'System Settings',
              'Configure platform settings',
              () {},
            ),
            _buildMenuItem(
              context,
              Icons.notifications,
              'Notifications',
              'Send announcements',
              () {},
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildSection('Account', [
            _buildMenuItem(
              context,
              Icons.person,
              'Admin Profile',
              'View and edit your profile',
              () {},
            ),
            _buildMenuItem(
              context,
              Icons.logout,
              'Logout',
              'Sign out of admin panel',
              () {},
              isDestructive: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.gray900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? AppColors.error : AppColors.gray400,
      ),
      onTap: onTap,
    );
  }
}
