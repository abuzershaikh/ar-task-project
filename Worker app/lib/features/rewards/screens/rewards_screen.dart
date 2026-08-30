import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Professional Worker Rewards & Daily Check-in Center:
/// - Clean, modern fintech/productivity design language.
/// - 7-Day interactive milestone timeline with earning multipliers.
/// - Daily check-in claim handler with real local state and countdown timer.
/// - Professional typography and crisp vector iconography (no arcade emojis).
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _currentStreak = 1;
  bool _canClaimToday = true;
  double _workerScore = 95.0;
  final String _workerTier = 'Gold Partner';
  bool _isClaiming = false;
  Timer? _countdownTimer;
  Duration _nextClaimRemaining = const Duration(hours: 18, minutes: 45);

  @override
  void initState() {
    super.initState();
    _loadStreakState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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

    HapticFeedback.lightImpact();
    setState(() => _isClaiming = true);

    final prefs = await SharedPreferences.getInstance();
    final nextStreak = (_currentStreak % 7) + 1;
    final now = DateTime.now();

    final addedScore = _getScoreForDay(_currentStreak);
    final cashBonus = _currentStreak == 7 ? 25.0 : 0.0;
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
      _showSuccessDialog(addedScore, cashBonus);
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

  void _showSuccessDialog(int addedScore, double cashBonus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00875A), size: 28),
            SizedBox(width: 10),
            Text(
              'Reward Claimed',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your daily check-in bonus of +$addedScore Quality Points has been credited.',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13.5),
            ),
            if (cashBonus > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Day 7 Milestone Bonus: ₹${cashBonus.toStringAsFixed(2)} added to your wallet!',
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTimer(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final currentMultiplier = _getMultiplierForDay(_currentStreak);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Rewards & Milestones',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  'Day $_currentStreak of 7',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Performance Overview Card ──────────────────────────
              _buildHeroCard(currentMultiplier),
              const SizedBox(height: 20),

              // ── 2. 7-Day Check-in Milestones ───────────────────────────────
              const Text(
                '7-Day Streak Timeline',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Check in daily to increase your reward multiplier and unlock weekly bonuses.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 14),

              _build7DayTimelineGrid(),
              const SizedBox(height: 16),

              // ── 3. Claim Daily Bonus Action ────────────────────────────────
              _buildClaimActionCard(),
              const SizedBox(height: 24),

              // ── 4. Tier Benefits & Multipliers ─────────────────────────────
              const Text(
                'Partner Privileges & Multipliers',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildBenefitsGrid(),
              const SizedBox(height: 20),

              // ── 5. Guidelines & Policy ─────────────────────────────────────
              _buildPolicyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(String currentMultiplier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 5),
                    Text(
                      _workerTier.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Score: ${_workerScore.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Multiplier',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentMultiplier,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00875A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00875A).withOpacity(0.4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Earning Boost',
                      style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Directly on every task',
                      style: TextStyle(color: Colors.white70, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Linear Progress Bar for 7-day streak
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _currentStreak / 7.0,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00875A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build7DayTimelineGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final isCompleted = dayNum < _currentStreak;
              final isCurrent = dayNum == _currentStreak;
              final isDay7 = dayNum == 7;
              final mult = _getMultiplierForDay(dayNum);

              Color cardBg = Colors.white;
              Color borderColor = const Color(0xFFE2E8F0);
              Color textColor = const Color(0xFF0F172A);

              if (isCurrent) {
                cardBg = const Color(0xFFF0FDF4);
                borderColor = const Color(0xFF00875A);
                textColor = const Color(0xFF00875A);
              } else if (isCompleted) {
                cardBg = const Color(0xFFF8FAFC);
                borderColor = const Color(0xFFCBD5E1);
                textColor = const Color(0xFF64748B);
              }

              return Container(
                width: 78,
                margin: EdgeInsets.only(right: index == 6 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
                  boxShadow: [
                    if (isCurrent)
                      BoxShadow(
                        color: const Color(0xFF00875A).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Day $dayNum',
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF00875A) : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF00875A)
                            : (isCurrent ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted
                              ? Icons.check_rounded
                              : (isDay7 ? Icons.stars_rounded : Icons.trending_up_rounded),
                          size: 15,
                          color: isCompleted
                              ? Colors.white
                              : (isCurrent ? const Color(0xFF00875A) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mult,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isDay7) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '+₹25',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildClaimActionCard() {
    final addedScore = _getScoreForDay(_currentStreak);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _canClaimToday ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _canClaimToday ? Icons.card_giftcard_rounded : Icons.schedule_rounded,
              color: _canClaimToday ? const Color(0xFF00875A) : const Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _canClaimToday ? 'Day $_currentStreak Check-in Ready' : 'Next Check-in Locked',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _canClaimToday
                      ? 'Claim +$addedScore Quality Score points'
                      : 'Unlocks in ${_formatTimer(_nextClaimRemaining)}',
                  style: TextStyle(
                    color: _canClaimToday ? const Color(0xFF00875A) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _canClaimToday && !_isClaiming ? _claimStreakBonus : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00875A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: _isClaiming
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_canClaimToday ? 'Claim' : 'Claimed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        _buildBenefitTile('Priority Feed Access', 'High paying campaigns first', Icons.bolt_rounded, const Color(0xFF0284C7)),
        _buildBenefitTile('Fast Approvals', 'Under 12-hour review queue', Icons.speed_rounded, const Color(0xFF00875A)),
        _buildBenefitTile('Bonus Multiplier', 'Up to +50% extra earnings', Icons.trending_up_rounded, const Color(0xFFD97706)),
        _buildBenefitTile('Instant Payouts', 'Automated wallet withdrawals', Icons.account_balance_wallet_rounded, const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _buildBenefitTile(String title, String subtitle, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF64748B)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Streak resets if you miss 48 hours without submitting at least 1 verified task. Multiplier applies to all base task earnings.',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
