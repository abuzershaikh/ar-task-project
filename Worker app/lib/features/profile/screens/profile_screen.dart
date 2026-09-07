import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'day_streak_screen.dart';
import 'quality_score_screen.dart';
import 'kyc_bank_details_screen.dart';

/// 🌿 3D Realistic Mayan Jungle Profile Screen
/// - Full Emerald & Mayan Gold color theme
/// - 3D realistic jungle hero pass card with ambient depth
/// - Google/Gmail profile photo with glowing multi-layer avatar ring
/// - 3D Bento stats cards (Earnings, Tasks, Quality Score, Streak)
/// - Modern settings & account controls with rich micro-details
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _notificationsEnabled = true;
  String? _googlePhotoUrl;

  // ── Color Theme Tokens ──────────────────────────────────────────────────
  static const Color _cardEmeraldBorder = Color(0xFF10B981);
  static const Color _goldPrimary = Color(0xFFF59E0B);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const Color _emeraldBright = Color(0xFF10B981);
  static const Color _emeraldLight = Color(0xFF34D399);
  static const Color _textWhite = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _resolveGooglePhoto();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
      context.read<TaskProvider>().fetchDashboardStats();
      context.read<TaskProvider>().fetchWalletData();
    });
  }

  Future<void> _resolveGooglePhoto() async {
    try {
      final googleSignIn = GoogleSignIn();
      GoogleSignInAccount? account = googleSignIn.currentUser;
      account ??= await googleSignIn.signInSilently();
      final url = account?.photoUrl;
      if (url != null && url.isNotEmpty) {
        if (mounted) {
          setState(() {
            _googlePhotoUrl = url;
          });
        }
      }
    } catch (e) {
      debugPrint('[PROFILE] Google photo check: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final user = authProvider.user;
    final profile = profileProvider.profileData;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Resolve Name, Email, Mobile, Age
    final name = (profile['profile'] is Map ? profile['profile']['name'] : null) ??
        profile['fullName'] ??
        user?['name'] ??
        firebaseUser?.displayName ??
        'Master Earner';

    final email = (profile['profile'] is Map ? profile['profile']['email'] : null) ??
        profile['email'] ??
        user?['email'] ??
        firebaseUser?.email ??
        'worker@taskpost.com';

    final mobile = (profile['profile'] is Map ? profile['profile']['mobile'] : null) ??
        profile['phone'] ??
        user?['phone'] ??
        '+91 ••••• •••••';

    final age = (profile['profile'] is Map ? profile['profile']['age'] : null)?.toString() ?? '24';
    final kycStatus = (profile['kycStatus'] ?? 'APPROVED').toString().toUpperCase();

    // Resolve Google / Gmail Photo URL
    String? photoUrl = _googlePhotoUrl ?? firebaseUser?.photoURL;
    if (photoUrl == null || photoUrl.isEmpty) {
      if (firebaseUser != null) {
        for (final p in firebaseUser.providerData) {
          if (p.photoURL != null && p.photoURL!.isNotEmpty) {
            photoUrl = p.photoURL;
            break;
          }
        }
      }
    }
    photoUrl ??= user?['photoUrl']?.toString() ??
        user?['photoURL']?.toString() ??
        profile['photoUrl']?.toString() ??
        profile['avatarUrl']?.toString();

    // Stats - 100% Live from Api & ProfileProvider
    final double rating = profileProvider.liveRating;

    final double qualityScore = profileProvider.liveQualityScore;

    final String totalEarnings = profile['totalEarnings']?.toString() ??
        taskProvider.dashboardStats['totalEarnings']?.toString() ??
        taskProvider.walletData['balance']?.toString() ??
        '0.00';

    final String workerId = user?['uid'] != null && user!['uid'].toString().length > 6
        ? user['uid'].toString().substring(0, 6).toUpperCase()
        : (profile['id'] != null && profile['id'].toString().length > 6
            ? profile['id'].toString().substring(0, 6).toUpperCase()
            : 'WKR-01');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF021911),
        body: Stack(
          children: [
            // Ambient Rainforest Image with emerald green colour shadowed across entire screen
            Positioned.fill(
              child: Image.asset(
                'assets/images/rainforest_pure_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF021911),
                ),
              ),
            ),
            // Emerald green shadowed gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF02170F).withValues(alpha: 0.82),
                      const Color(0xFF03261B).withValues(alpha: 0.88),
                      const Color(0xFF021810).withValues(alpha: 0.94),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: _emeraldBright,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await Future.wait([
                    profileProvider.fetchProfile(),
                    taskProvider.fetchDashboardStats(),
                    taskProvider.fetchWalletData(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── 1. Top Bar ───────────────────────────────────────────────
                      _buildTopAppBar(context, name, email, mobile, age),
                      const SizedBox(height: 18),

                      // ── 2. 3D Jungle Hero VIP Worker Card ────────────────────────
                      _buildJungleHeroCard(
                        name: name,
                        email: email,
                        photoUrl: photoUrl,
                        workerId: workerId,
                        kycStatus: kycStatus,
                        totalEarnings: totalEarnings,
                      ),
                      const SizedBox(height: 22),

                      // ── 3. Account & Identity Section ────────────────────────────
                    _buildSectionHeader('Account & Identity', Icons.shield_outlined),
                    const SizedBox(height: 12),
                    _buildAccountCard(
                      context: context,
                      name: name,
                      email: email,
                      mobile: mobile,
                      age: age,
                      kycStatus: kycStatus,
                    ),
                    const SizedBox(height: 24),

                    // ── 6. Rewards & Performance Section ─────────────────────────
                    _buildSectionHeader('Rewards & Progression', Icons.stars_rounded),
                    const SizedBox(height: 12),
                    _buildRewardsCard(context, qualityScore, rating),
                    const SizedBox(height: 24),

                    // ── 7. Preferences & Security ─────────────────────────────────
                    _buildSectionHeader('Preferences & Security', Icons.tune_rounded),
                    const SizedBox(height: 12),
                    _buildSettingsCard(context, authProvider),
                    const SizedBox(height: 32),

                    // ── 8. Logout Button ─────────────────────────────────────────
                    _buildLogoutButton(context, authProvider),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  // ── Top App Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopAppBar(
    BuildContext context,
    String name,
    String email,
    String mobile,
    String age,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _emeraldBright,
                boxShadow: [
                  BoxShadow(
                    color: _emeraldBright,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Worker Profile',
              style: GoogleFonts.poppins(
                color: _textWhite,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0B3326).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _cardEmeraldBorder.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, color: _goldLight, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Edit Info',
                  style: GoogleFonts.poppins(
                    color: _goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 3D Jungle Hero VIP Worker Card ─────────────────────────────────────────
  Widget _buildJungleHeroCard({
    required String name,
    required String email,
    required String? photoUrl,
    required String workerId,
    required String kycStatus,
    required String totalEarnings,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _cardEmeraldBorder.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _emeraldBright.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // Background Artwork
            Positioned.fill(
              child: Image.asset(
                'assets/images/rainforest_pure_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF063524), Color(0xFF031A12)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // Rich Gradient Overlay for legibility & magical contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF02160F).withValues(alpha: 0.72),
                      const Color(0xFF032218).withValues(alpha: 0.85),
                      const Color(0xFF02120C).withValues(alpha: 0.94),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Card Header: VIP Badge & Guild Emblem
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Verified Guild Member Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E4734), Color(0xFF062D20)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _emeraldLight.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _emeraldBright.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _emeraldLight,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'MAYAN ELITE GUILD',
                              style: GoogleFonts.poppins(
                                color: _goldLight,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3D Worker Guild Emblem Thumbnail
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _goldPrimary.withValues(alpha: 0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _goldPrimary.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/worker_elite_badge.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.verified_rounded,
                              color: _goldPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Middle Row: Glowing Avatar + Name + Gmail
                  Row(
                    children: [
                      // 3D Glowing Avatar Ring
                      _buildGlowingAvatar(photoUrl, name),
                      const SizedBox(width: 16),

                      // User Credentials
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: _textWhite,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 13,
                                  color: Color(0xFF6EE7B7),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFA7F3D0),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // ID Tag & KYC Status Pill
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Text(
                                    '#$workerId',
                                    style: GoogleFonts.poppins(
                                      color: _textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildKycChip(kycStatus),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bottom Divider & Tier Level Progress
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.military_tech_rounded, color: _goldPrimary, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            'Rank: Mayan Hunter (Tier 2)',
                            style: GoogleFonts.poppins(
                              color: _goldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Level 3: 75%',
                        style: GoogleFonts.poppins(
                          color: _emeraldLight,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // 3D Level Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 7,
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.75,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_emeraldBright, _goldPrimary],
                                ),
                              ),
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
      ),
    );
  }

  // ── 3D Glowing Avatar with Google Profile Photo ─────────────────────────────
  Widget _buildGlowingAvatar(String? photoUrl, String name) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Outer glow & gradient ring
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_emeraldBright, _goldPrimary, _emeraldLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _emeraldBright.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: _goldPrimary.withValues(alpha: 0.25),
                blurRadius: 20,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF031911),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(name),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 74,
                          height: 74,
                          color: const Color(0xFF09291E),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _emeraldBright,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : _buildFallbackAvatar(name),
            ),
          ),
        ),

        // Verified Shield Badge at Bottom-Right
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_goldPrimary, Color(0xFFD97706)],
            ),
            border: Border.all(color: const Color(0xFF041811), width: 2),
            boxShadow: [
              BoxShadow(
                color: _goldPrimary.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: Colors.black,
            size: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'W';
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.3),
          radius: 0.85,
          colors: [
            Color(0xFF15664B),
            Color(0xFF093627),
            Color(0xFF031911),
          ],
        ),
        border: Border.all(
          color: _goldPrimary.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _goldLight.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
          ),
          Text(
            initial,
            style: GoogleFonts.cinzel(
              color: _goldLight,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: _goldPrimary.withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycChip(String kycStatus) {
    final bool isVerified = kycStatus == 'VERIFIED' || kycStatus == 'APPROVED';
    final Color color = isVerified ? _emeraldLight : _goldPrimary;
    final String label = isVerified ? 'KYC Verified' : 'KYC Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  // ── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.40)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF34D399)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Account Card ────────────────────────────────────────────────────────────
  Widget _buildAccountCard({
    required BuildContext context,
    required String name,
    required String email,
    required String mobile,
    required String age,
    required String kycStatus,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Edit Personal Details',
            subtitle: 'Name, phone number & age',
            trailing: _buildPill('Edit', const Color(0xFF059669)),
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
          _buildDivider(),
          _buildListTile(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFFD97706),
            title: 'Bank & UPI Settlement',
            subtitle: 'Receive instant direct task payouts',
            trailing: _buildPill(
              kycStatus == 'VERIFIED' ? 'Verified' : 'Update',
              kycStatus == 'VERIFIED' ? const Color(0xFF059669) : const Color(0xFFD97706),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KycBankDetailsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.g_mobiledata_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Google Account Linked',
            subtitle: email,
            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ── Rewards Card ────────────────────────────────────────────────────────────
  Widget _buildRewardsCard(BuildContext context, double qualityScore, double rating) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.local_fire_department_outlined,
            iconColor: const Color(0xFFEA580C),
            title: 'Daily Streak & 2X Multiplier',
            subtitle: 'Maintain consecutive task activity',
            trailing: _buildPill('Active 🔥', const Color(0xFFEA580C)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DayStreakScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.stars_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Quality Score & Accuracy',
            subtitle: '${qualityScore.toStringAsFixed(1)}% score  •  ${rating > 0 ? "${rating.toStringAsFixed(1)} avg rating" : "New Worker"}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 4),
                Text(
                  rating > 0 ? rating.toStringAsFixed(1) : 'New',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB45309),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QualityScoreScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Settings Card ───────────────────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF059669), size: 20),
            ),
            title: Text(
              'Push Notifications',
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Instant alerts when new tasks are available',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
            trailing: Switch(
              value: _notificationsEnabled,
              activeThumbColor: const Color(0xFF059669),
              activeTrackColor: const Color(0xFFA7F3D0),
              inactiveThumbColor: const Color(0xFF94A3B8),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
              },
            ),
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF0284C7),
            title: 'Help Center & Support',
            subtitle: 'Get assistance with tasks or payouts',
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF064E3B),
                  content: Text(
                    '24/7 Worker Support available at support@taskpost.com',
                    style: GoogleFonts.poppins(color: const Color(0xFFA7F3D0)),
                  ),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.policy_outlined,
            iconColor: const Color(0xFF7C3AED),
            title: 'Terms of Service & Rules',
            subtitle: 'Guidelines for submitting quality proofs',
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ── Logout Button ───────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _confirmLogout(context, authProvider),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Text(
                'Logout from Worker App',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFDC2626),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out from your worker profile?',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────
  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.10),
          border: Border.all(color: iconColor.withValues(alpha: 0.20)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: const Color(0xFF64748B),
          fontSize: 11,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
