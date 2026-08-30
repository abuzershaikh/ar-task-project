import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'day_streak_screen.dart';
import 'quality_score_screen.dart';
import 'kyc_bank_details_screen.dart';
import '../../../core/providers/profile_provider.dart';

/// Professional Worker Profile Screen
/// - Poppins font throughout for clean, modern typography
/// - No emojis — uses Material icons only
/// - Subtle gradients, refined spacing, professional color palette
/// - Premium card-based layout with polished micro details
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  // ── Color Palette ───────────────────────────────────────────────────────────
  static const _bgColor = Color(0xFFF1F5F9);
  static const _cardColor = Colors.white;
  static const _headingColor = Color(0xFF0F172A);
  static const _mutedColor = Color(0xFF94A3B8);
  static const _borderColor = Color(0xFFE2E8F0);
  static const _accentBlue = Color(0xFF2563EB);
  static const _accentAmber = Color(0xFFD97706);
  static const _accentGreen = Color(0xFF059669);
  static const _accentSky = Color(0xFF0284C7);
  static const _dangerColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final user = authProvider.user;
    final profile = profileProvider.profileData;

    final name = (profile['profile'] is Map ? profile['profile']['name'] : null) ?? profile['fullName'] ?? user?['name'] ?? 'Worker Name';
    final email = (profile['profile'] is Map ? profile['profile']['email'] : null) ?? profile['email'] ?? user?['email'] ?? 'worker@example.com';
    final mobile = (profile['profile'] is Map ? profile['profile']['mobile'] : null) ?? profile['phone'] ?? 'Not Set';
    final age = (profile['profile'] is Map ? profile['profile']['age'] : null)?.toString() ?? 'Not Set';
    final kycStatus = profile['kycStatus'] ?? 'DRAFT';

    final double rating = (profile['averageRating'] != null && double.tryParse(profile['averageRating'].toString()) != null && double.parse(profile['averageRating'].toString()) > 0)
        ? double.parse(profile['averageRating'].toString())
        : (profile['score']?['breakdown']?['rating'] != null ? (double.tryParse(profile['score']['breakdown']['rating'].toString()) ?? 4.9) : 4.9);

    final double qualityScore = (profile['score'] != null && profile['score']['totalScore'] != null)
        ? (double.tryParse(profile['score']['totalScore'].toString()) ?? 96.5)
        : (profile['score']?['overallScore'] != null ? (double.tryParse(profile['score']['overallScore'].toString()) ?? 96.5) : 96.5);

    final int completedTasks = int.tryParse(profile['totalTasksCompleted']?.toString() ?? '0') ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Header with gradient background ────────────────────
              _buildTopHeader(context, name, email, mobile, age, kycStatus),

              // ── 2. Performance Stats Row ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: _buildStatsRow(qualityScore, rating, completedTasks),
                ),
              ),

              // ── 3. Menu Items ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: GoogleFonts.poppins(
                        color: _headingColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMenuCard(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: _accentBlue,
                      title: 'Edit Profile',
                      subtitle: 'Name, mobile, age & email',
                      trailing: _buildChip('Editable', _accentBlue),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              initialName: name,
                              initialEmail: email,
                              initialMobile: mobile,
                              initialAge: age,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuCard(
                      icon: Icons.account_balance_outlined,
                      iconBg: const Color(0xFFF0F9FF),
                      iconColor: _accentSky,
                      title: 'Payout & Bank Details',
                      subtitle: 'Bank account, UPI or PayPal',
                      trailing: _buildChip(
                        kycStatus == 'VERIFIED' ? 'Verified' : 'Update',
                        kycStatus == 'VERIFIED' ? _accentGreen : _accentAmber,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const KycBankDetailsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Performance',
                      style: GoogleFonts.poppins(
                        color: _headingColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMenuCard(
                      icon: Icons.local_fire_department_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: _accentAmber,
                      title: 'Daily Streak & Rewards',
                      subtitle: '7-day task streak & bonus multipliers',
                      trailing: _buildChip('Active', _accentGreen),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DayStreakScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuCard(
                      icon: Icons.insights_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: _accentAmber,
                      title: 'Quality Score & Rating',
                      subtitle: '${qualityScore.toStringAsFixed(1)}% score  |  ${rating.toStringAsFixed(1)} rating',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: _accentAmber),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              color: _accentAmber,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QualityScoreScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── 4. Logout Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _dangerColor.withValues(alpha: 0.3)),
                          foregroundColor: _dangerColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: _dangerColor),
                            const SizedBox(width: 8),
                            Text(
                              'Logout Account',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header Section ──────────────────────────────────────────────────────
  Widget _buildTopHeader(
    BuildContext context,
    String name,
    String email,
    String mobile,
    String age,
    String kycStatus,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A5F),
            Color(0xFF1E3A8A),
          ],
        ),
      ),
      child: Column(
        children: [
          // Title bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(
                        initialName: name,
                        initialEmail: email,
                        initialMobile: mobile,
                        initialAge: age,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white70,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 38,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Contact info
          Text(
            '$email  |  $mobile',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // KYC status badge
          _buildKycBadge(kycStatus),
        ],
      ),
    );
  }

  // ── KYC Status Badge ────────────────────────────────────────────────────────
  Widget _buildKycBadge(String kycStatus) {
    IconData icon;
    String label;
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (kycStatus == 'VERIFIED') {
      icon = Icons.verified_rounded;
      label = 'KYC Verified';
      bgColor = _accentGreen.withValues(alpha: 0.15);
      textColor = const Color(0xFF34D399);
      borderColor = _accentGreen.withValues(alpha: 0.25);
    } else if (kycStatus == 'SUBMITTED') {
      icon = Icons.schedule_rounded;
      label = 'KYC Pending';
      bgColor = _accentAmber.withValues(alpha: 0.15);
      textColor = const Color(0xFFFBBF24);
      borderColor = _accentAmber.withValues(alpha: 0.25);
    } else {
      icon = Icons.info_outline_rounded;
      label = 'KYC Incomplete';
      bgColor = _dangerColor.withValues(alpha: 0.12);
      textColor = const Color(0xFFFCA5A5);
      borderColor = _dangerColor.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row (3 Stat Cards overlapping header) ─────────────────────────────
  Widget _buildStatsRow(double qualityScore, double rating, int completedTasks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QualityScoreScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                Icons.verified_outlined,
                _accentGreen,
                '${qualityScore.toStringAsFixed(1)}%',
                'Quality',
              ),
            ),
            Container(width: 1, height: 36, color: _borderColor),
            Expanded(
              child: _buildStatItem(
                Icons.star_outline_rounded,
                _accentAmber,
                rating.toStringAsFixed(1),
                'Rating',
              ),
            ),
            Container(width: 1, height: 36, color: _borderColor),
            Expanded(
              child: _buildStatItem(
                Icons.task_alt_outlined,
                _accentSky,
                '$completedTasks',
                'Tasks',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: _headingColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _mutedColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Menu Card ───────────────────────────────────────────────────────────────
  Widget _buildMenuCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: _headingColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: _mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing
                trailing,
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _mutedColor.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Small Chip/Badge ────────────────────────────────────────────────────────
  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
