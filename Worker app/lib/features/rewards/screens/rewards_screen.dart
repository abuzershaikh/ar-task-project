import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌴 3D Jungle Adventure Strike & Multiplier Trail Screen:
/// - Game-style winding stone road map through the tropical jungle
/// - Distinct ancient Mayan jungle temple artwork (jungle_strike_bg.jpg)
/// - 7-Day interactive stepping stone milestones with active flame & vine states
/// - Day 7 Grand Finale featuring the 3D Treasure Chest Lottie animation
/// - Focuses purely on Task Earning Multipliers & Quality Score (no direct cash text)
/// - Real-time countdown timer, daily check-in handler, and SharedPreferences persistence
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  int _currentStreak = 1;
  bool _canClaimToday = true;
  double _workerScore = 95.0;
  final String _workerTier = 'Gold Partner';
  bool _isClaiming = false;
  Timer? _countdownTimer;
  Duration _nextClaimRemaining = const Duration(hours: 18, minutes: 45);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadStreakState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakState() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt('worker_daily_streak') ?? 1;
    final lastClaimMillis = prefs.getInt('worker_last_streak_claim') ?? 0;
    final savedScore = prefs.getDouble('worker_local_score') ?? 95.0;

    final now = DateTime.now();
    bool canClaim = true;
    Duration remaining = Duration.zero;

    if (lastClaimMillis > 0) {
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastClaimMillis);
      final isSameDay = lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;
      if (isSameDay) {
        canClaim = false;
        final midnight = DateTime(now.year, now.month, now.day + 1);
        remaining = midnight.difference(now);
      } else {
        final diffDays = now.difference(lastDate).inDays;
        if (diffDays > 1) {
          await prefs.setInt('worker_daily_streak', 1);
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentStreak = (prefs.getInt('worker_daily_streak') ?? streak).clamp(1, 7);
        _workerScore = savedScore;
        _canClaimToday = canClaim;
        _nextClaimRemaining = remaining;
      });
    }

    if (!canClaim) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_nextClaimRemaining.inSeconds <= 0) {
        timer.cancel();
        setState(() => _canClaimToday = true);
      } else {
        setState(() {
          _nextClaimRemaining = _nextClaimRemaining - const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _claimStreakBonus() async {
    if (!_canClaimToday || _isClaiming) return;

    HapticFeedback.heavyImpact();
    setState(() => _isClaiming = true);

    final prefs = await SharedPreferences.getInstance();
    final nextStreak = (_currentStreak % 7) + 1;
    final now = DateTime.now();

    final addedScore = _getScoreForDay(_currentStreak);
    final isGrand = _currentStreak == 7;
    final newScore = (_workerScore + (addedScore / 10)).clamp(0.0, 100.0);

    await prefs.setInt('worker_daily_streak', nextStreak);
    await prefs.setInt('worker_last_streak_claim', now.millisecondsSinceEpoch);
    await prefs.setDouble('worker_local_score', newScore);

    setState(() {
      _isClaiming = false;
      _canClaimToday = false;
      _currentStreak = nextStreak;
      _workerScore = newScore;
      final midnight = DateTime(now.year, now.month, now.day + 1);
      _nextClaimRemaining = midnight.difference(now);
    });

    _startCountdown();

    if (mounted) {
      _show3DCelebrationDialog(addedScore, isGrand);
    }
  }

  int _getScoreForDay(int day) {
    switch (day) {
      case 1: return 10;
      case 2: return 15;
      case 3: return 25;
      case 4: return 35;
      case 5: return 50;
      case 6: return 75;
      case 7: return 150;
      default: return 10;
    }
  }

  String _getMultiplierForDay(int day) {
    switch (day) {
      case 1: return '1.05x';
      case 2: return '1.10x';
      case 3: return '1.15x';
      case 4: return '1.20x';
      case 5: return '1.30x';
      case 6: return '1.40x';
      case 7: return '1.50x';
      default: return '1.05x';
    }
  }

  String _formatTimer(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  void _show3DCelebrationDialog(int addedScore, bool isGrand) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF032B18),
                Color(0xFF01140B),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Treasure Chest Lottie Animation
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/animations/treasure_box.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFF59E0B),
                      size: 80,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Text(
                isGrand ? 'EPIC TREASURE UNLOCKED!' : 'STRIKE REWARD UNLOCKED!',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4ADE80),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Daily Strike bonus of +$addedScore Quality Score points credited to your profile.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              if (isGrand) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        '1.50x Max Task Boost Active!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFF22C55E).withValues(alpha: 0.5),
                  ),
                  child: Text(
                    'CLAIM & CONTINUE',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMilestoneInfoDialog(int day) {
    final pts = _getScoreForDay(day);
    final mult = _getMultiplierForDay(day);
    final isDone = day < _currentStreak;
    final isCurrent = day == _currentStreak;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF032617),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF084E2B), width: 1.2),
        ),
        title: Row(
          children: [
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : isCurrent
                      ? Icons.local_fire_department_rounded
                      : Icons.lock_outline_rounded,
              color: isDone
                  ? const Color(0xFF22C55E)
                  : isCurrent
                      ? const Color(0xFFF59E0B)
                      : Colors.white38,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Day $day Jungle Milestone',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reward: +$pts Quality Points',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4ADE80),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Multiplier Boost: $mult on all completed tasks',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12.5,
              ),
            ),
            if (day == 7) ...[
              const SizedBox(height: 8),
              Text(
                'Grand Prize: Epic 3D Treasure Chest with maximum earning rate!',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMultiplier = _getMultiplierForDay(_currentStreak);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF01140B), // Deep Dark Jungle Emerald
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Jungle Ancient Temple Hero with Strike Hub ──────────
              _buildTopJungleHero(topPadding, currentMultiplier),
              const SizedBox(height: 18),

              // ── 2. Interactive Big Claim Action Bar ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildClaimActionBar(currentMultiplier),
              ),
              const SizedBox(height: 28),

              // ── 3. 3D Game Adventure Road Map Header ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.explore_rounded,
                          color: Color(0xFF4ADE80),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '7-Day Adventure Trail',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E2B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Day $_currentStreak / 7',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4ADE80),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Follow the ancient jungle path daily to multiply task earnings and claim the Grand Treasure Chest on Day 7.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. The 3D Winding Road Map ────────────────────────────────
              _build3DJungleRoadMap(),
              const SizedBox(height: 28),

              // ── 5. Jungle Strike Privileges & Perks Grid ────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Strike Multiplier Privileges',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildJunglePerksGrid(),
              ),
              const SizedBox(height: 24),

              // ── 6. Bottom Jungle Foliage ───────────────────────────────────
              _buildBottomFoliage(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Jungle Ancient Temple Hero ─────────────────────────────────────
  Widget _buildTopJungleHero(double topPadding, String currentMultiplier) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Distinct 3D Ancient Jungle Temple & Ruins Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/jungle_strike_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
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

          // 2. Smooth Vignette & Dark Emerald Shadow Fade
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
                  stops: const [0.0, 0.40, 0.75, 1.0],
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

          // 4. Foreground Content: Header Bar & Hero Multiplier Card
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
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
                                  text: 'Jungle ',
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
                                  text: 'Strike',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF59E0B),
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
                            'Daily Multiplier & Quest Road',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Top Right Streak Counter Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_currentStreak Days',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Multiplier 3D Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF03351C).withValues(alpha: 0.90),
                        const Color(0xFF011A0E).withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                        blurRadius: 25,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 3D Pulsating Flame Emblem
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFFFDE047),
                                Color(0xFFF59E0B),
                                Color(0xFFD97706),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Multiplier Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF064E2B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _workerTier.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF4ADE80),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Score: ${_workerScore.toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF34D399),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$currentMultiplier Earning Boost',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Directly multiplies earnings on every task',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Interactive Big Claim Action Bar ────────────────────────────────────
  Widget _buildClaimActionBar(String currentMultiplier) {
    if (_canClaimToday) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _claimStreakBonus,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'CLAIM DAY $_currentStreak STRIKE BONUS (+${_getScoreForDay(_currentStreak)} PTS)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF032617),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF084E2B),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF064E2B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF4ADE80),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Jungle Reward In',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimer(_nextClaimRemaining),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFBBF24),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF064E2B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'CLAIMED',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4ADE80),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── 3. The 3D Winding Road Map ────────────────────────────────────────────
  Widget _build3DJungleRoadMap() {
    // 7 Milestone node configurations (Zigzag S-Curve)
    final nodes = [
      _MilestoneConfig(day: 1, title: 'Day 1', reward: '+10 Pts', mult: '1.05x', xAlign: -0.65),
      _MilestoneConfig(day: 2, title: 'Day 2', reward: '+15 Pts', mult: '1.10x', xAlign: 0.65),
      _MilestoneConfig(day: 3, title: 'Day 3', reward: '+25 Pts', mult: '1.15x', xAlign: -0.55),
      _MilestoneConfig(day: 4, title: 'Day 4', reward: '+35 Pts', mult: '1.20x', xAlign: 0.55),
      _MilestoneConfig(day: 5, title: 'Day 5', reward: '+50 Pts', mult: '1.30x', xAlign: -0.60),
      _MilestoneConfig(day: 6, title: 'Day 6', reward: '+75 Pts', mult: '1.40x', xAlign: 0.60),
      _MilestoneConfig(day: 7, title: 'Day 7', reward: 'Epic Chest', mult: '1.50x', xAlign: 0.0, isGrand: true),
    ];

    const double mapHeight = 720.0;

    return Container(
      width: double.infinity,
      height: mapHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF021B11),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF084E2B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // 1. Subtle Ancient Temple Backdrop
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/images/jungle_strike_bg.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),

            // 2. Custom Painted 3D Winding Cobblestone Road & Vines
            Positioned.fill(
              child: CustomPaint(
                painter: _JungleRoadPainter(
                  currentStreak: _currentStreak,
                ),
              ),
            ),

            // 3. The 7 Stepping Stone Nodes positioned along the trail
            ...List.generate(nodes.length, (index) {
              final node = nodes[index];
              final double yFraction = (index + 0.5) / nodes.length;

              return Align(
                alignment: Alignment(node.xAlign, (yFraction * 2) - 1),
                child: _buildMilestoneNode(node),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneNode(_MilestoneConfig node) {
    final bool isDone = node.day < _currentStreak;
    final bool isCurrent = node.day == _currentStreak;

    if (node.isGrand) {
      // Day 7 Grand Finale Treasure Chest Node
      return GestureDetector(
        onTap: () {
          if (isCurrent && _canClaimToday) {
            _claimStreakBonus();
          } else {
            _showMilestoneInfoDialog(node.day);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Aura Ring
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isCurrent
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.7)
                            : isDone
                                ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                                : Colors.black54,
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

                // 3D Treasure Box Lottie
                SizedBox(
                  width: 95,
                  height: 95,
                  child: Lottie.asset(
                    'assets/animations/treasure_box.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFF59E0B),
                        size: 55,
                      );
                    },
                  ),
                ),

                if (isDone)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'DAY 7 • EPIC CHEST',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Days 1-6 Stepping Stones
    return GestureDetector(
      onTap: () {
        if (isCurrent && _canClaimToday) {
          _claimStreakBonus();
        } else {
          _showMilestoneInfoDialog(node.day);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDone
                    ? [const Color(0xFF22C55E), const Color(0xFF065F46)]
                    : isCurrent
                        ? [const Color(0xFFFDE047), const Color(0xFFD97706)]
                        : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              ),
              border: Border.all(
                color: isDone
                    ? const Color(0xFF86EFAC)
                    : isCurrent
                        ? const Color(0xFFFDE047)
                        : const Color(0xFF334155),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                      : isDone
                          ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                          : Colors.black54,
                  blurRadius: isCurrent ? 18 : 10,
                  spreadRadius: isCurrent ? 2 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                  : isCurrent
                      ? const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30)
                      : const Icon(Icons.lock_rounded, color: Colors.white38, size: 22),
            ),
          ),
          const SizedBox(height: 4),

          // Day Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFFD97706)
                  : isDone
                      ? const Color(0xFF064E2B)
                      : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFFFDE047)
                    : isDone
                        ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                        : Colors.white12,
              ),
            ),
            child: Text(
              '${node.title} • ${node.mult}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Jungle Perks & Multiplier Privileges Grid ───────────────────────────
  Widget _buildJunglePerksGrid() {
    final perks = [
      _PerkItem(
        icon: Icons.bolt_rounded,
        title: 'Task Multiplier',
        desc: 'All task payouts boosted up to 1.50x automatically.',
        color: const Color(0xFFF59E0B),
      ),
      _PerkItem(
        icon: Icons.shield_rounded,
        title: 'Streak Shield',
        desc: 'Protected by automated strike grace periods.',
        color: const Color(0xFF38BDF8),
      ),
      _PerkItem(
        icon: Icons.workspace_premium_rounded,
        title: 'VIP Partner Tier',
        desc: 'Unlock exclusive high-paying VIP enterprise tasks.',
        color: const Color(0xFF4ADE80),
      ),
      _PerkItem(
        icon: Icons.card_giftcard_rounded,
        title: 'Epic Jungle Chest',
        desc: 'Unlock legendary 3D treasure vaults on Day 7.',
        color: const Color(0xFFA78BFA),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: perks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final perk = perks[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF032617),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: perk.color.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(perk.icon, color: perk.color, size: 24),
              const SizedBox(height: 8),
              Text(
                perk.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                perk.desc,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 5. Bottom Jungle Foliage Base ──────────────────────────────────────────
  Widget _buildBottomFoliage() {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/jungle_bottom_leaves.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
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
                    const Color(0xFF01140B).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneConfig {
  final int day;
  final String title;
  final String reward;
  final String mult;
  final double xAlign;
  final bool isGrand;

  _MilestoneConfig({
    required this.day,
    required this.title,
    required this.reward,
    required this.mult,
    required this.xAlign,
    this.isGrand = false,
  });
}

class _PerkItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  _PerkItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

/// Custom painter for the 3D winding cobblestone jungle road
class _JungleRoadPainter extends CustomPainter {
  final int currentStreak;

  _JungleRoadPainter({required this.currentStreak});

  @override
  void paint(Canvas canvas, Size size) {
    // 7 waypoints matching the node alignment
    final points = [
      Offset(size.width * 0.18, size.height * (0.5 / 7)),
      Offset(size.width * 0.82, size.height * (1.5 / 7)),
      Offset(size.width * 0.22, size.height * (2.5 / 7)),
      Offset(size.width * 0.78, size.height * (3.5 / 7)),
      Offset(size.width * 0.20, size.height * (4.5 / 7)),
      Offset(size.width * 0.80, size.height * (5.5 / 7)),
      Offset(size.width * 0.50, size.height * (6.5 / 7)),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;

      path.cubicTo(
        p0.dx, midY,
        p1.dx, midY,
        p1.dx, p1.dy,
      );
    }

    // 1. Outer Dark Mud & Moss Path Shadow
    final roadShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, roadShadowPaint);

    // 2. Cobblestone Trail Base
    final roadBasePaint = Paint()
      ..color = const Color(0xFF0F3A22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, roadBasePaint);

    // 3. Glowing Living Jungle Vine Line
    final vinePaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, vinePaint);

    // 4. Stepping Stone pavers along the curve
    final paverPaint = Paint()
      ..color = const Color(0xFF1E5B37)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 12, paverPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _JungleRoadPainter oldDelegate) =>
      oldDelegate.currentStreak != currentStreak;
}

/// Custom painter for glowing ambient fireflies
class _JungleFireflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fireflyGlowPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final fireflyCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

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
