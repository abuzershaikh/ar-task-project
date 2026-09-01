import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

import '../../../service_builder/presentation/pages/services_list_screen.dart';
import '../../../service_builder/presentation/pages/task_expiry_settings_screen.dart';
import '../../../service_builder/presentation/pages/app_update_management_screen.dart';
import 'system_settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin User',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SUPER_ADMIN',
                        style: TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Engine & System
          const _SectionTitle(title: 'Engine & System'),
          _MenuItem(
            icon: Icons.system_update_rounded,
            title: 'App Version & Updates',
            subtitle: 'Manage forced update list & APK download URLs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppUpdateManagementScreen()),
              );
            },
          ),
          _MenuItem(
            icon: Icons.timer_outlined,
            title: 'Task Expiration & Auto-Reassign',
            subtitle: 'Configure worker completion & pool expiry timeouts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskExpirySettingsScreen()),
              );
            },
          ),
          _MenuItem(
            icon: Icons.psychology_outlined,
            title: 'Matching Brain',
            subtitle: 'Configure scoring & matching engine',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.shopping_basket_outlined,
            title: 'Services & Pricing',
            subtitle: 'Manage service catalog & margins',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesListScreen()),
              );
            },
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'System Settings',
            subtitle: 'Platform configuration & financial rules',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SystemSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),

          // Operations
          const _SectionTitle(title: 'Operations'),
          _MenuItem(
            icon: Icons.rate_review_outlined,
            title: 'Reviews',
            subtitle: 'Pending submissions & approvals',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.verified_user_outlined,
            title: 'KYC Management',
            subtitle: 'Worker verification requests',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payouts',
            subtitle: 'Worker withdrawal requests',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          const SizedBox(height: 16),

          // Finance
          const _SectionTitle(title: 'Finance'),
          _MenuItem(
            icon: Icons.account_balance_outlined,
            title: 'Finance & Ledger',
            subtitle: 'Platform financial overview',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'Buyer Payments',
            subtitle: 'Payment history & reconciliation',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          const SizedBox(height: 16),

          // Analytics & Monitoring
          const _SectionTitle(title: 'Analytics & Monitoring'),
          _MenuItem(
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            subtitle: 'Platform metrics & insights',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.warning_amber_outlined,
            title: 'Risk & Fraud',
            subtitle: 'Suspicious activity monitoring',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          const SizedBox(height: 16),

          // SaaS & API
          const _SectionTitle(title: 'SaaS & API'),
          _MenuItem(
            icon: Icons.api_outlined,
            title: 'API Management',
            subtitle: 'API clients, keys & usage',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.webhook_outlined,
            title: 'Webhooks',
            subtitle: 'Event delivery & monitoring',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          const SizedBox(height: 16),

          // Admin
          const _SectionTitle(title: 'Administration'),
          _MenuItem(
            icon: Icons.history_outlined,
            title: 'Audit Logs',
            subtitle: 'System activity tracking',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Platform alerts & messages',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Roles',
            subtitle: 'Manage admin permissions',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          const SizedBox(height: 16),

          // Profile
          const _SectionTitle(title: 'Profile'),
          _MenuItem(
            icon: Icons.person_outline,
            title: 'My Profile',
            subtitle: 'Update your information',
            onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon'))); },
          ),
          _MenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from admin panel',
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            isDestructive: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.gray500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDestructive ? AppColors.error : AppColors.gray900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.gray400,
        ),
      ),
    );
  }
}
