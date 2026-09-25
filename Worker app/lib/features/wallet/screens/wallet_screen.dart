import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import 'withdrawal_screen.dart';
import 'transactions_history_screen.dart';
import '../../notifications/screens/notification_history_screen.dart';

/// Jungle Themed Wallet Screen:
/// - Full-screen immersive rainforest background with ambient sun rays & canopy mist
/// - Authentic 3D Gaming Carved Wooden Board (SVG) with embedded gold medallion & recessed balance slot
/// - Live balance & privacy eye toggle accurately positioned inside the wooden slot
/// - Gamified Milestone Progress Bar to ₹100 instant cashout threshold
/// - Jungle-themed Quick Actions & Withdrawal Info with glowing fireflies & live tropical rain
/// - Living Animated Jungle Parrot on Branch preserved with 100% fidelity
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
      child: Theme(
        data: Theme.of(context).copyWith(
          primaryTextTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).primaryTextTheme),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
            fontFamily: 'Poppins',
          ),
        ),
        child: Scaffold(
        backgroundColor: const Color(0xFF01140B), // Deep Dark Jungle Emerald
        body: Stack(
          children: [
            // ── 1. Full-Screen Realistic Rainforest Background Image ───────
            Positioned.fill(
              child: Image.asset(
                'assets/images/rainforest_pure_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/jungle_wallet_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ── 2. Deep Emerald Atmosphere & Dark Vignette Overlay ────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF01140B).withValues(alpha: 0.65),
                      const Color(0xFF01140B).withValues(alpha: 0.78),
                      const Color(0xFF01140B).withValues(alpha: 0.90),
                      const Color(0xFF01140B),
                    ],
                    stops: const [0.0, 0.35, 0.72, 1.0],
                  ),
                ),
              ),
            ),

            // ── 3. Dynamic Rainforest Rain Overlay (Behind cards & text) ──
            const Positioned.fill(
              child: IgnorePointer(
                child: _DynamicRainforestRainOverlay(),
              ),
            ),

            // ── 4. Ambient Glowing Fireflies Overlay ──────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _JungleFireflyPainter(),
                ),
              ),
            ),

            // ── 5. Foreground Scrollable Content & Jungle Gaming Cards ─────
            RefreshIndicator(
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
                    // ── 1. Top Jungle Canopy with Gaming Wooden Board ──────
                    _buildJungleTopHero(context, topPadding, walletBalance),
                    const SizedBox(height: 16),

                    // ── 2. Withdrawal Milestone Progress Card ──────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildJungleWithdrawalInfoCard(walletBalance),
                    ),
                    const SizedBox(height: 22),

                    // ── 3. Quick Actions Section ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Actions',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Button 1: Withdraw Earnings (Instant UPI / Bank)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildJungleActionButton(
                        context: context,
                        title: 'Withdraw Earnings',
                        subtitle: 'Instant direct transfer to UPI ID or Bank Account',
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
                        subtitle: 'Complete verified ledger of payouts & earnings',
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

                    // ── 5. Bottom Jungle Foliage with Animated Living Parrot
                    _buildJungleBottomFoliage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── Top Jungle Canopy Header with Gaming Wooden Board ───────────────────────
  Widget _buildJungleTopHero(
    BuildContext context,
    double topPadding,
    double walletBalance,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Realistic 3D Jungle Canopy Header Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/jungle_wallet_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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

          // 2. Smooth Vignette & Dark Emerald Fade into Content
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.transparent,
                    const Color(0xFF01140B).withValues(alpha: 0.50),
                    const Color(0xFF01140B),
                  ],
                  stops: const [0.0, 0.40, 0.80, 1.0],
                ),
              ),
            ),
          ),

          // 3. Foreground Content: Header Bar & 3D Gaming Wooden Signboard
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header Title Row ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                        color: Colors.black.withValues(alpha: 0.9),
                                        blurRadius: 8,
                                        offset: const Offset(1, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                TextSpan(
                                  text: 'Wallet',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF4ADE80),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.9),
                                        blurRadius: 8,
                                        offset: const Offset(1, 2),
                                      ),
                                      Shadow(
                                        color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF22C55E),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Available Earnings & Cashout',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right Actions: Audio Toggle + Privacy Eye + Notification Bell
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Jungle Audio Toggle
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
                                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
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
                                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
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
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF032617).withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
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
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── 3D Gaming Wooden Signboard Balance Display (SVG) ────────
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth > 440 ? 440.0 : constraints.maxWidth;
                      // Proportions: 500 width / 150 height (3.333 ratio)
                      final barHeight = barWidth / (500 / 150);

                      return SizedBox(
                        width: barWidth,
                        height: barHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Gaming Carved Wooden Board SVG
                            Positioned.fill(
                              child: SvgPicture.asset(
                                'assets/svg/wallet_wooden_board.svg',
                                fit: BoxFit.fill,
                              ),
                            ),

                            // 2. User Balance accurately centered in the recessed plate
                            Positioned(
                              left: barWidth * 0.30,
                              right: barWidth * 0.08,
                              top: barHeight * 0.33,
                              bottom: barHeight * 0.12,
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _isBalanceVisible
                                        ? '₹${walletBalance.toStringAsFixed(2)}'
                                        : '₹ • • • •',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFFFBEB),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.95),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                        Shadow(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                                          blurRadius: 18,
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Gamified Withdrawal Milestone Progress Card ─────────────────────────────
  Widget _buildJungleWithdrawalInfoCard(double walletBalance) {
    final bool isEligible = walletBalance >= 100;
    final double progress = (walletBalance / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF032617),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEligible
              ? const Color(0xFF22C55E).withValues(alpha: 0.6)
              : const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isEligible ? const Color(0xFF054528) : const Color(0xFF2E1905),
            const Color(0xFF021B0F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: isEligible
                ? const Color(0xFF22C55E).withValues(alpha: 0.25)
                : const Color(0xFFF59E0B).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEligible
                        ? [const Color(0xFF16A34A), const Color(0xFF065F46)]
                        : [const Color(0xFFD97706), const Color(0xFF78350F)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEligible ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isEligible
                          ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  isEligible ? Icons.verified_rounded : Icons.lock_clock_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEligible
                          ? '🎉 Instant Cashout Unlocked!'
                          : 'Payout Milestone (Min. ₹100)',
                      style: GoogleFonts.poppins(
                        color: isEligible ? const Color(0xFF4ADE80) : const Color(0xFFFDE047),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEligible
                          ? 'Zero fees • Direct to UPI / Bank transfer'
                          : 'Earn ₹${(100 - walletBalance).clamp(0, 100).toStringAsFixed(0)} more to cashout immediately',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEligible
                      ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEligible ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                    width: 1,
                  ),
                ),
                child: Text(
                  isEligible ? 'READY' : '${(progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    color: isEligible ? const Color(0xFF86EFAC) : const Color(0xFFFEF08A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Animated Milestone Progress Track
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEligible
                          ? [const Color(0xFF22C55E), const Color(0xFF86EFAC)]
                          : [const Color(0xFFF59E0B), const Color(0xFFFDE047)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: (isEligible ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹0',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isEligible ? '₹100 (Threshold Reached)' : '₹100 Target',
                style: GoogleFonts.poppins(
                  color: isEligible ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
          color: const Color(0xFF22C55E).withValues(alpha: 0.35),
          width: 1.2,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063A22),
            Color(0xFF022013),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
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
                      color: iconColor.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
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
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF4ADE80),
                    size: 13,
                  ),
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

          // 3. Dynamic Animated Jungle Parrot on Branch (Touches left edge + can fly away and return)
          const Positioned(
            left: -8,
            bottom: 0,
            width: 160,
            height: 160,
            child: _AnimatedJungleParrotBranch(),
          ),
        ],
      ),
    );
  }
}

/// Dynamic Living Jungle Parrot on Branch:
/// - Branch is always solid & visible on the left edge
/// - 🎲 Fully randomized: Sometimes parrot is absent on open, sometimes present
/// - Randomized flight intervals (15-45s) and away times (10-35s)
/// - User can tap the parrot to trigger a fly-away animation
class _AnimatedJungleParrotBranch extends StatefulWidget {
  const _AnimatedJungleParrotBranch();

  @override
  State<_AnimatedJungleParrotBranch> createState() => _AnimatedJungleParrotBranchState();
}

class _AnimatedJungleParrotBranchState extends State<_AnimatedJungleParrotBranch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flightController;
  late final Animation<Offset> _flightOffsetAnimation;
  late final Animation<double> _flightFadeAnimation;
  late final Animation<double> _flightScaleAnimation;
  final math.Random _random = math.Random();
  Timer? _flightTimer;
  bool _isAway = false;

  @override
  void initState() {
    super.initState();
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _flightOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, -1.5),
    ).animate(CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic,
    ));

    _flightFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _flightController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _flightScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.65,
    ).animate(CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic,
    ));

    // 🎲 Random presence on screen open: 45% chance parrot is already away in the jungle!
    _isAway = _random.nextDouble() < 0.45;
    if (_isAway) {
      _flightController.value = 1.0; // Starts hidden off-screen
      _scheduleReturn(initialDelaySeconds: 6 + _random.nextInt(16));
    } else {
      _flightController.value = 0.0; // Starts perched on branch
      _scheduleFlyAway(initialDelaySeconds: 12 + _random.nextInt(28));
    }
  }

  void _scheduleFlyAway({int? initialDelaySeconds}) {
    _flightTimer?.cancel();
    final delay = Duration(seconds: initialDelaySeconds ?? (15 + _random.nextInt(30)));
    _flightTimer = Timer(delay, () {
      if (!mounted || _isAway) return;
      _triggerFlyAway();
    });
  }

  void _scheduleReturn({int? initialDelaySeconds}) {
    _flightTimer?.cancel();
    final delay = Duration(seconds: initialDelaySeconds ?? (10 + _random.nextInt(25)));
    _flightTimer = Timer(delay, () {
      if (!mounted || !_isAway) return;
      _triggerReturn();
    });
  }

  void _triggerFlyAway() {
    if (_isAway) return;
    _flightTimer?.cancel();
    setState(() => _isAway = true);
    _flightController.forward().then((_) {
      if (mounted) {
        _scheduleReturn();
      }
    });
  }

  void _triggerReturn() {
    if (!_isAway) return;
    _flightTimer?.cancel();
    _flightController.reverse().then((_) {
      if (mounted) {
        setState(() => _isAway = false);
        _scheduleFlyAway();
      }
    });
  }

  @override
  void dispose() {
    _flightTimer?.cancel();
    _flightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        children: [
          // 1. Solid Tree Branch touching the left edge (Always visible)
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/parrot_branch_only.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),

          // 2. Animated Parrot that flies into jungle canopy and returns + Tap trigger
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!_isAway) {
                  _triggerFlyAway();
                }
              },
              child: SlideTransition(
                position: _flightOffsetAnimation,
                child: FadeTransition(
                  opacity: _flightFadeAnimation,
                  child: ScaleTransition(
                    scale: _flightScaleAnimation,
                    alignment: Alignment.center,
                    child: Lottie.asset(
                      'assets/animations/parrot_bird_only.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic Rainforest Rain Overlay:
/// - Fine, delicate continuous tropical rain (barik barik boondein) in background
/// - Translucent misty droplets (6px - 14px length, 0.75px thin stroke)
class _DynamicRainforestRainOverlay extends StatefulWidget {
  const _DynamicRainforestRainOverlay();

  @override
  State<_DynamicRainforestRainOverlay> createState() =>
      _DynamicRainforestRainOverlayState();
}

class _DynamicRainforestRainOverlayState
    extends State<_DynamicRainforestRainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rainController;
  late final List<_RainDrop> _rainDrops;
  final math.Random _random = math.Random();
  Timer? _weatherTimer;
  double _targetRainOpacity = 0.75;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _rainDrops = List.generate(110, (_) => _RainDrop(_random));

    _scheduleWeatherTransition();
  }

  void _scheduleWeatherTransition() {
    _weatherTimer?.cancel();
    final duration = Duration(seconds: 18 + _random.nextInt(22));
    _weatherTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        if (_targetRainOpacity > 0.4) {
          // Soft ambient mist drizzle
          _targetRainOpacity = 0.35 + _random.nextDouble() * 0.25;
        } else {
          // Lush refreshing tropical rain
          _targetRainOpacity = 0.70 + _random.nextDouble() * 0.25;
        }
      });
      _scheduleWeatherTransition();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _targetRainOpacity,
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      child: AnimatedBuilder(
        animation: _rainController,
        builder: (context, child) {
          return CustomPaint(
            painter: _RainforestRainPainter(
              progress: _rainController.value,
              rainDrops: _rainDrops,
            ),
          );
        },
      ),
    );
  }
}

class _RainDrop {
  final double x;
  final double speed;
  final double length;
  final double opacity;
  final double offset;

  _RainDrop(math.Random rand)
      : x = rand.nextDouble(),
        speed = 0.70 + rand.nextDouble() * 0.55,
        length = 6.0 + rand.nextDouble() * 8.0, // Small fine droplets (6px - 14px)
        opacity = 0.15 + rand.nextDouble() * 0.32,
        offset = rand.nextDouble();
}

class _RainforestRainPainter extends CustomPainter {
  final double progress;
  final List<_RainDrop> rainDrops;

  _RainforestRainPainter({
    required this.progress,
    required this.rainDrops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..strokeWidth = 0.75 // Fine and delicate
      ..strokeCap = StrokeCap.round;

    for (final drop in rainDrops) {
      // Rain starts above the top status & notification bar (y = -35.0) and cascades smoothly
      final y = ((drop.offset + progress * drop.speed) % 1.0) *
              (size.height + drop.length + 50) -
          35.0;
      final x = drop.x * size.width;

      const slant = 2.0; // Gentle natural angle
      rainPaint.color =
          const Color(0xFFBAE6FD).withValues(alpha: drop.opacity);

      canvas.drawLine(
        Offset(x, y),
        Offset(x - slant, y + drop.length),
        rainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainforestRainPainter oldDelegate) => true;
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
