import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'day_streak_screen.dart';
import 'quality_score_screen.dart';
import 'kyc_bank_details_screen.dart';
import '../../../core/providers/profile_provider.dart';

/// Main Profile Overview Screen:
/// - Styled with Warm Gold Amber (#F59E0B / #D97706) & Slate theme tokens.
/// - Avatar Header with Pencil Edit Badge (clicking opens EditProfileScreen).
/// - 3 Feature Cards:
///   1) "Edit Profile Data" (Name, Mobile, Age, Email autofetched)
///   2) "Daily Streak" (7 Days Streak 🔥)
///   3) "Quality Score & Rating" (98.5% / 4.9★ ⭐)
/// - Logout Account button.
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

    final double rating = (profile['averageRating'] != null) ? double.parse(profile['averageRating'].toString()) : 4.8;
    final double qualityScore = (profile['score'] != null && profile['score']['totalScore'] != null)
        ? double.parse(profile['score']['totalScore'].toString())
        : 94.2;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Header Bar ────────────────────────────────────────
              _buildHeaderBar(),
              const SizedBox(height: 20),

              // ── 2. Avatar Profile Header Card ────────────────────────────
              _buildProfileHeaderCard(context, name, email, mobile, age, kycStatus),
              const SizedBox(height: 24),

              // ── 3. Profile Navigation Cards Section ───────────────────────
              const Text(
                'Account & Performance',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Card 1: Edit Profile Data (Pencil)
              _buildNavigationCard(
                context: context,
                title: 'Edit Profile Data',
                subtitle: 'Update name, mobile number & age (Email autofetched)',
                icon: Icons.edit_rounded,
                iconBgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                badgeText: 'Editable',
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
              const SizedBox(height: 12),

              // Card 2: Daily Streak
              _buildNavigationCard(
                context: context,
                title: 'Daily Streak & Rewards',
                subtitle: '7-Day active task streak & bonus multipliers',
                icon: Icons.local_fire_department_rounded,
                iconBgColor: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFF59E0B),
                badgeText: '7 Days 🔥',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DayStreakScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Card 3: Quality Score & Rating
              _buildNavigationCard(
                context: context,
                title: 'Quality Score & Rating',
                subtitle: '${qualityScore.toStringAsFixed(1)}% quality score • ${rating.toStringAsFixed(1)}★ rating & badges',
                icon: Icons.star_rounded,
                iconBgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                badgeText: '${rating.toStringAsFixed(1)} ⭐',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QualityScoreScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Card 4: Payout & Bank Details
              _buildNavigationCard(
                context: context,
                title: 'Payout & Bank Details',
                subtitle: 'Add bank, UPI or PayPal for withdrawals',
                icon: Icons.account_balance_rounded,
                iconBgColor: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                badgeText: kycStatus == 'VERIFIED' ? 'Verified' : 'Update',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const KycBankDetailsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── 4. Logout Account Button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    foregroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Logout Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Worker ',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'Profile',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF334155),
            size: 20,
          ),
        ),
      ],
    );
  }

  // ── Profile Header Card with Pencil Edit Icon Button ───────────────────────
  Widget _buildProfileHeaderCard(
    BuildContext context,
    String name,
    String email,
    String mobile,
    String age,
    String kycStatus,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + Pencil Edit Icon Badge
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 46,
                  color: Color(0xFFD97706),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Email & Mobile Subtitle
          Text(
            '$mobile  •  $email',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // KYC Verified Pill
          if (kycStatus == 'VERIFIED')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: Color(0xFF00875A)),
                  SizedBox(width: 5),
                  Text(
                    'KYC Verified Worker',
                    style: TextStyle(
                      color: Color(0xFF00875A),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else if (kycStatus == 'SUBMITTED')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_actions_rounded, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 5),
                  Text(
                    'KYC Pending Approval',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                  SizedBox(width: 5),
                  Text(
                    'KYC Unverified',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Navigation Action Card ─────────────────────────────────────────────────
  Widget _buildNavigationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
