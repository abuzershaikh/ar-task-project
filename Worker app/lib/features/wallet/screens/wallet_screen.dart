import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import 'withdrawal_screen.dart';
import 'transactions_history_screen.dart';

/// Jungle Themed Wallet Screen:
/// - Edge-to-edge 3D tropical jungle canopy header with realistic monstera foliage & golden sunlight
/// - Standalone 3D CoinBar Lottie balance holder (all extra card boxes, 100% payout text, circles removed)
/// - Live balance & privacy eye toggle accurately positioned inside the golden coin bar slot
/// - Jungle-themed Quick Actions & Withdrawal Info with glowing fireflies & lush foliage
/// - Low-volume soothing ambient jungle bird chirping sound effect matching theme
class WalletScreen extends StatefulWidget {
  final bool isCurrentTab;

  const WalletScreen({
    super.key,
    this.isCurrentTab = true,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  bool _isBalanceVisible = true;
  bool _isMuted = false;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchWalletData();
    });
    _initJungleAudio();
  }

  Future<void> _initJungleAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setVolume(0.25); // Gentle ambient rainforest volume
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      if (widget.isCurrentTab && !_isMuted) {
        await _audioPlayer?.play(AssetSource('audio/jungle_rainforest_ambient.ogg'));
      } else {
        await _audioPlayer?.setSource(AssetSource('audio/jungle_rainforest_ambient.ogg'));
      }
    } catch (_) {
      // Audio playback fails gracefully if unsupported
    }
  }

  @override
  void didUpdateWidget(covariant WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTab != oldWidget.isCurrentTab) {
      if (widget.isCurrentTab && !_isMuted) {
        _audioPlayer?.resume().catchError((_) {
          _audioPlayer?.play(AssetSource('audio/jungle_rainforest_ambient.ogg'));
        });
      } else {
        _audioPlayer?.pause();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _audioPlayer?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.isCurrentTab && !_isMuted) {
        _audioPlayer?.resume();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final wallet = taskProvider.walletData;
    final double walletBalance =
        (wallet['balance'] ?? wallet['availableBalance'] ?? 0.0).toDouble();

    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF01140B), // Deep Dark Jungle Emerald
        body: RefreshIndicator(
          color: const Color(0xFF22C55E),
          backgroundColor: const Color(0xFF032617),
          onRefresh: () async {
            await taskProvider.fetchWalletData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Jungle Canopy with CoinBar Lottie Balance ─────────
                _buildJungleTopHero(context, topPadding, walletBalance),
                const SizedBox(height: 18),

                // ── 2. Withdrawal Rules & Info Banner ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildJungleWithdrawalInfoCard(walletBalance),
                ),
                const SizedBox(height: 22),

                // ── 3. Quick Actions Section ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button 1: Withdraw Earnings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildJungleActionButton(
                    context: context,
                    title: 'Withdraw Earnings',
                    subtitle: 'Transfer funds directly to your UPI ID or Bank',
                    icon: Icons.account_balance_wallet_rounded,
                    iconBgColor: const Color(0xFF064E2B),
                    iconColor: const Color(0xFF4ADE80),
                    badgeText: 'Instant',
                    badgeBg: const Color(0xFF047857),
                    badgeColor: const Color(0xFFD1FAE5),
                    onTap: () async {
                      _audioPlayer?.pause();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WithdrawalScreen(
                            availableBalance: walletBalance,
                          ),
                        ),
                      );
                      if (mounted && widget.isCurrentTab && !_isMuted) {
                        _audioPlayer?.resume();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Button 2: Transaction History
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildJungleActionButton(
                    context: context,
                    title: 'Transaction History',
                    subtitle: 'View detailed records of payouts & earnings',
                    icon: Icons.receipt_long_rounded,
                    iconBgColor: const Color(0xFF0F3A4A),
                    iconColor: const Color(0xFF38BDF8),
                    badgeText: 'Logs',
                    badgeBg: const Color(0xFF0369A1),
                    badgeColor: const Color(0xFFE0F2FE),
                    onTap: () async {
                      _audioPlayer?.pause();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TransactionsHistoryScreen(),
                        ),
                      );
                      if (mounted && widget.isCurrentTab && !_isMuted) {
                        _audioPlayer?.resume();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── 4. Bottom Jungle Foliage & Plant Base ─────────────────────
                _buildJungleBottomFoliage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Jungle Canopy Header with Standalone CoinBar ───────────────────────
  Widget _buildJungleTopHero(
    BuildContext context,
    double topPadding,
    double walletBalance,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Realistic 3D Jungle Canopy Background Image
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 290 + topPadding,
            child: Image.asset(
              'assets/images/jungle_wallet_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF021B0F),
                        Color(0xFF03351C),
                        Color(0xFF01140B),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Gradient Overlay for smooth blending into dark jungle base
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 290 + topPadding,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    const Color(0xFF01140B).withValues(alpha: 0.85),
                    const Color(0xFF01140B),
                  ],
                  stops: const [0.0, 0.4, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // 3. Glowing Firefly Particles
          Positioned.fill(
            child: CustomPaint(
              painter: _JungleFireflyPainter(),
            ),
          ),

          // 4. Foreground Content: Title Bar & Standalone CoinBar Lottie
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header Row ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'My ',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              TextSpan(
                                text: 'Wallet',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF22C55E),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Available Earnings & Cashout',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Right Actions: Audio Toggle + Eye Toggle + Notification Bell
                    Row(
                      children: [
                        // Jungle Ambient Audio Toggle (Mute/Unmute)
                        InkWell(
                          onTap: () async {
                            setState(() {
                              _isMuted = !_isMuted;
                            });
                            if (_isMuted) {
                              await _audioPlayer?.setVolume(0.0);
                            } else {
                              await _audioPlayer?.setVolume(0.18);
                            }
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF032617).withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: _isMuted ? Colors.white38 : const Color(0xFF4ADE80),
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Show/Hide Privacy Eye Toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isBalanceVisible = !_isBalanceVisible;
                            });
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF032617).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isBalanceVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF4ADE80),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isBalanceVisible ? 'Hide' : 'Show',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Notification Bell
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF032617).withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Standalone 3D CoinBar Lottie Balance Display ─────────────
                // Clean and organic: No outer box, no extra 100% payout text, no circles!
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth > 420 ? 420.0 : constraints.maxWidth;
                      // Ratio 500:150 (3.333)
                      final barHeight = barWidth / (500 / 148);

                      return SizedBox(
                        width: barWidth,
                        height: barHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. CoinBar Lottie Animation (500x150)
                            Positioned.fill(
                              child: Lottie.asset(
                                'assets/animations/coin_bar.json',
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 2. User Balance accurately centered inside the golden CoinBar slot
                            Positioned(
                              left: barWidth * 0.31,
                              right: barWidth * 0.12,
                              top: barHeight * 0.25,
                              bottom: barHeight * 0.18,
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _isBalanceVisible
                                        ? '₹${walletBalance.toStringAsFixed(2)}'
                                        : '₹••••••',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.95),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: const Color(0xFFD97706).withValues(alpha: 0.6),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Jungle Themed Withdrawal Rules Info Card ────────────────────────────────
  Widget _buildJungleWithdrawalInfoCard(double walletBalance) {
    final bool isEligible = walletBalance >= 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF032617),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEligible
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isEligible
                  ? const Color(0xFF064E2B)
                  : const Color(0xFF3B2304),
              shape: BoxShape.circle,
              border: Border.all(
                color: isEligible
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF59E0B),
                width: 1.2,
              ),
            ),
            child: Icon(
              isEligible ? Icons.verified_rounded : Icons.info_outline_rounded,
              color: isEligible
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFFBBF24),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEligible ? 'Eligible for Instant Withdrawal' : 'Minimum Limit ₹100',
                  style: GoogleFonts.poppins(
                    color: isEligible
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFFBBF24),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min. ₹100 • Max. ₹10,000 per payout request (Zero Fees)',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
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

  // ── Jungle Themed Action Button ─────────────────────────────────────────────
  Widget _buildJungleActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF032617),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF08482A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 23),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.poppins(
                                color: badgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF22C55E),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Jungle Plants & Foliage Base with Animated Parrot ──────────────
  Widget _buildJungleBottomFoliage() {
    return SizedBox(
      width: double.infinity,
      height: 175,
      child: Stack(
        children: [
          // 1. 3D Realistic Jungle Bottom Leaves Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/jungle_bottom_leaves.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),

          // 2. Gradient blending overlay from top to bottom
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF01140B),
                    const Color(0xFF01140B).withValues(alpha: 0.5),
                    Colors.transparent,
                    const Color(0xFF01140B).withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // 3. Animated Jungle Parrot sitting on branch extending from left edge
          Positioned(
            left: -8,
            bottom: 0,
            width: 160,
            height: 160,
            child: Lottie.asset(
              'assets/animations/parrot.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for ambient golden glowing fireflies in the jungle
class _JungleFireflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fireflyGlowPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final fireflyCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Glowing firefly positions
    final fireflies = [
      Offset(size.width * 0.15, size.height * 0.22),
      Offset(size.width * 0.38, size.height * 0.16),
      Offset(size.width * 0.82, size.height * 0.28),
      Offset(size.width * 0.65, size.height * 0.45),
      Offset(size.width * 0.22, size.height * 0.72),
      Offset(size.width * 0.88, size.height * 0.68),
      Offset(size.width * 0.50, size.height * 0.82),
    ];

    for (final pos in fireflies) {
      canvas.drawCircle(pos, 3.5, fireflyGlowPaint);
      canvas.drawCircle(pos, 1.2, fireflyCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
