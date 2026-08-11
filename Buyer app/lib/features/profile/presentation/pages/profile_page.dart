import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    'B',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Buyer Name',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'buyer@example.com',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.editProfile);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Business Profile
          _buildMenuSection(
            context,
            'Business',
            [
              _buildMenuItem(
                context,
                'Business Profile',
                Icons.business_outlined,
                () => Navigator.pushNamed(context, AppRouter.businessProfile),
              ),
              _buildMenuItem(
                context,
                'Invoices',
                Icons.receipt_outlined,
                () => Navigator.pushNamed(context, AppRouter.invoices),
              ),
              _buildMenuItem(
                context,
                'Payments',
                Icons.payment_outlined,
                () => Navigator.pushNamed(context, AppRouter.payments),
              ),
            ],
          ),
          
          // Support
          _buildMenuSection(
            context,
            'Support & Help',
            [
              _buildMenuItem(
                context,
                'Help Center',
                Icons.help_outline,
                () => Navigator.pushNamed(context, AppRouter.helpCenter),
              ),
              _buildMenuItem(
                context,
                'Contact Support',
                Icons.headset_mic_outlined,
                () => Navigator.pushNamed(context, AppRouter.support),
              ),
            ],
          ),
          
          // Settings
          _buildMenuSection(
            context,
            'Settings',
            [
              _buildMenuItem(
                context,
                'Settings',
                Icons.settings_outlined,
                () => Navigator.pushNamed(context, AppRouter.settings),
              ),
              _buildMenuItem(
                context,
                'Notifications',
                Icons.notifications_outlined,
                () => Navigator.pushNamed(context, AppRouter.notifications),
              ),
            ],
          ),
          
          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () {
                _showLogoutDialog(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Logout'),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
              Navigator.pop(dialogContext);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
