import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// ProfilePage - Buyer Profile Screen
/// Is page par Google Sign-In ya Email login se fetch hua Buyer Name, Email, Profile Picture, aur details load hote hain.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Buyer Account';
  String _userEmail = 'buyer@marketingpro.com';
  String? _userPhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user credentials saved from Google Sign-In / Auth
  Future<void> _loadUserProfile() async {
    final storage = getIt<SecureStorageService>();
    final name = await storage.getUserName();
    final email = await storage.getUserEmail();
    final photo = await storage.getUserPhoto();

    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (email != null && email.isNotEmpty) _userEmail = email;
        if (photo != null && photo.isNotEmpty) _userPhotoUrl = photo;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // ── Profile Header Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Profile Avatar / Google Photo
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  backgroundImage: _userPhotoUrl != null ? NetworkImage(_userPhotoUrl!) : null,
                  child: _userPhotoUrl == null
                      ? Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'B',
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // Name & Email
                Text(
                  _userName,
                  style: AppTextStyles.heading3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.editProfile);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Business Profile ────────────────────────────────────
          _buildMenuSection(
            context,
            'Business & Orders',
            [
              _buildMenuItem(
                context,
                'Business Details & GST',
                Icons.business_outlined,
                () => Navigator.pushNamed(context, AppRouter.businessProfile),
              ),
              _buildMenuItem(
                context,
                'Billing & Invoices',
                Icons.receipt_outlined,
                () => Navigator.pushNamed(context, AppRouter.invoices),
              ),
              _buildMenuItem(
                context,
                'Payment Methods',
                Icons.payment_outlined,
                () => Navigator.pushNamed(context, AppRouter.payments),
              ),
            ],
          ),

          // ── Support & Help ──────────────────────────────────────
          _buildMenuSection(
            context,
            'Support & Help',
            [
              _buildMenuItem(
                context,
                'Help Center & FAQ',
                Icons.help_outline,
                () => Navigator.pushNamed(context, AppRouter.helpCenter),
              ),
              _buildMenuItem(
                context,
                'Contact Support Team',
                Icons.headset_mic_outlined,
                () => Navigator.pushNamed(context, AppRouter.support),
              ),
            ],
          ),

          // ── App Preferences ────────────────────────────────────
          _buildMenuSection(
            context,
            'Settings',
            [
              _buildMenuItem(
                context,
                'App Preferences',
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

          // ── Logout CTA ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout Account', style: TextStyle(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.8,
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
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your Marketing Pro buyer account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              context.read<AuthBloc>().add(LogoutEvent());
              await getIt<SecureStorageService>().clearAll();
              if (context.mounted) {
                Navigator.pop(dialogContext);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
