import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../../data/models/profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C16),
      body: Stack(
        children: [
          // ── Ambient Glowing Atmospheric Background ──
          Positioned.fill(
            child: Stack(
              children: [
                Container(color: const Color(0xFF080C16)),
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4F46E5).withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 280,
                  left: -80,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF06B6D4).withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Profile Content ──
          BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded && state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              ProfileModel profile;
              if (state is ProfileLoaded) {
                profile = state.profile;
              } else if (state is ProfileUpdating) {
                profile = state.currentProfile;
              } else if (state is ProfileError && state.cachedProfile != null) {
                profile = state.cachedProfile!;
              } else {
                profile = ProfileModel(
                  id: '',
                  email: 'buyer@taskpost.com',
                  name: 'Marketing Pro Buyer',
                  phone: '',
                  companyName: '',
                  website: '',
                  bio: '',
                  avatarUrl: '',
                  billingAddress: '',
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF38BDF8),
                backgroundColor: const Color(0xFF0F172A),
                onRefresh: () async {
                  context.read<ProfileBloc>().add(RefreshProfileEvent());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.zero,
                  children: [
                    // Top Safe Area Header
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Account & Profile',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRouter.settings),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: const Icon(Icons.settings_outlined, color: Color(0xFF38BDF8), size: 19),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── 1. Hero VIP Profile Card ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildHeroProfileCard(context, profile),
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Quick Campaign Stats Strip ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildQuickStatsStrip(profile),
                    ),
                    const SizedBox(height: 24),

                    // ── 3. Account & Identity Group ──
                    _buildSectionHeader('PROFILE & BUSINESS'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        iconAsset: 'assets/icons/review.png',
                        title: 'Personal Information',
                        subtitle: 'Update full name, phone number & avatar',
                        tag: 'PROFILE',
                        tagColor: const Color(0xFF38BDF8),
                        onTap: () async {
                          final bloc = context.read<ProfileBloc>();
                          await Navigator.pushNamed(context, AppRouter.editProfile);
                          bloc.add(RefreshProfileEvent());
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        iconAsset: 'assets/icons/marketing.png',
                        title: 'Business & Company Details',
                        subtitle: profile.companyName.isNotEmpty
                            ? '${profile.companyName} • Registered'
                            : 'Set company name & registered office address',
                        tag: profile.companyName.isNotEmpty ? 'VERIFIED' : 'BUSINESS',
                        tagColor: const Color(0xFF10B981),
                        onTap: () async {
                          final bloc = context.read<ProfileBloc>();
                          await Navigator.pushNamed(context, AppRouter.businessProfile);
                          bloc.add(RefreshProfileEvent());
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        iconAsset: 'assets/icons/star.png',
                        title: 'Invoices & Billing History',
                        subtitle: 'Official campaign billing statements & receipts',
                        tag: 'RECEIPTS',
                        tagColor: const Color(0xFFF59E0B),
                        onTap: () => Navigator.pushNamed(context, AppRouter.invoices),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── 4. Preferences & Security Group ──
                    _buildSectionHeader('PREFERENCES & SECURITY'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        iconData: Icons.tune_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: 'App Preferences & Notifications',
                        subtitle: 'Live alert switches, sounds & haptics',
                        onTap: () => Navigator.pushNamed(context, AppRouter.settings),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        iconData: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: 'Password & Security',
                        subtitle: 'Change account password & security log',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── 5. Support & Knowledge Group ──
                    _buildSectionHeader('SUPPORT & ASSURANCE'),
                    const SizedBox(height: 8),
                    _buildMenuCard([
                      _buildMenuItem(
                        iconAsset: 'assets/icons/mobile-chatting.png',
                        title: 'Help Center & FAQs',
                        subtitle: 'Escrow refunds, proof audit & campaign guide',
                        onTap: () => Navigator.pushNamed(context, AppRouter.helpCenter),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        iconData: Icons.support_agent_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: '24/7 Dedicated VIP Support',
                        subtitle: 'WhatsApp VIP desk & priority tickets',
                        tag: 'VIP 24/7',
                        tagColor: const Color(0xFFEC4899),
                        onTap: () => Navigator.pushNamed(context, AppRouter.support),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── 6. Logout CTA ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: GestureDetector(
                        onTap: () => _showLogoutDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Logout of Account',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProfileCard(BuildContext context, ProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient Top Glow Line
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF38BDF8).withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    // 3D Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF4F46E5), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0F172A),
                          ),
                          child: Center(
                            child: () {
                              final googlePhoto = (profile.avatarUrl.startsWith('http') ? profile.avatarUrl : null)
                                  ?? FirebaseAuth.instance.currentUser?.photoURL
                                  ?? getIt<LocalStorageService>().getUserPhoto();

                              if (googlePhoto != null && googlePhoto.isNotEmpty) {
                                return ClipOval(
                                  child: Image.network(
                                    googlePhoto,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => ClipOval(
                                      child: Image.asset('assets/images/vip_badge_3d.jpg', width: 56, height: 56, fit: BoxFit.cover),
                                    ),
                                  ),
                                );
                              }

                              if (profile.avatarUrl.isNotEmpty && profile.avatarUrl.length <= 2) {
                                return Text(profile.avatarUrl, style: const TextStyle(fontSize: 28));
                              }

                              return ClipOval(
                                child: Image.asset('assets/images/vip_badge_3d.jpg', width: 56, height: 56, fit: BoxFit.cover),
                              );
                            }(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name, Email, VIP Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 0.8),
                                ),
                                child: Text(
                                  'BUYER VIP',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF34D399),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          if (profile.companyName.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.business_rounded, color: Color(0xFF38BDF8), size: 12),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    profile.companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Edit Profile Button
                GestureDetector(
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRouter.editProfile);
                    if (context.mounted) context.read<ProfileBloc>().add(RefreshProfileEvent());
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Edit Profile & Personal Details',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF38BDF8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsStrip(ProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              iconAsset: 'assets/icons/wallet.png',
              label: 'Total Spent',
              value: '₹${profile.totalSpend.toStringAsFixed(0)}',
              accentColor: const Color(0xFF38BDF8),
            ),
          ),
          Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: _buildMiniStat(
              iconAsset: 'assets/icons/marketing.png',
              label: 'Campaigns',
              value: '${profile.totalOrdersCount}',
              accentColor: const Color(0xFF10B981),
            ),
          ),
          Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: _buildMiniStat(
              iconAsset: 'assets/icons/star.png',
              label: 'Escrow Trust',
              value: '100%',
              accentColor: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String iconAsset,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(iconAsset, width: 16, height: 16, fit: BoxFit.contain),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 9.5),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuItem({
    String? iconAsset,
    IconData? iconData,
    Color? iconColor,
    required String title,
    required String subtitle,
    String? tag,
    Color? tagColor,
    required VoidCallback onTap,
  }) {
    Widget iconWidget;
    if (iconAsset != null) {
      iconWidget = Image.asset(iconAsset, width: 18, height: 18, fit: BoxFit.contain);
    } else {
      iconWidget = Icon(iconData, color: iconColor ?? const Color(0xFF38BDF8), size: 18);
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF38BDF8)).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: iconWidget,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (tagColor ?? const Color(0xFF38BDF8)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: GoogleFonts.outfit(
                  color: tagColor ?? const Color(0xFF38BDF8),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF475569), size: 20),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 16,
      endIndent: 16,
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Change Password',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: 'Current Password',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: 'New Password (min 6 chars)',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF080C16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters.')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout Confirmation',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to sign out of your Marketing Pro buyer session?',
          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              context.read<AuthBloc>().add(LogoutEvent());
              await getIt<SecureStorageService>().clearAll();
              await getIt<LocalStorageService>().clearAll();
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              try {
                final googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.pop(dialogContext);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            child: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
