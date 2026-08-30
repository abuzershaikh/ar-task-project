import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 3D Game Road Map (Zig-Zag Neon Energy Road & Moving Avatar):
/// - S-Curve Zig-Zag Neon Pipeline rendered via high-performance CustomPainter.
/// - 3D Isometric stepping stage platforms with physical bevel depth.
/// - Floating Worker Avatar pawn hovering above current active streak stage.
/// - Grand 3D Day 7 Mega Cyber Vault at the end of the road.
/// - Tactile 3D pressable arcade claim button with real physical sink-down on tap.
/// - 100% self-contained in Flutter with local persistent state.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with TickerProviderStateMixin {
  int _currentStreak = 1;
  bool _canClaimToday = true;
  double _workerScore = 95.0;
  final String _workerTier = 'GOLD';
  bool _isClaiming = false;
  bool _isButtonPressed = false;
  Timer? _countdownTimer;
  Duration _nextClaimRemaining = const Duration(hours: 19, minutes: 30);

  // Avatar Floating & Pulse Controllers
  late AnimationController _avatarHoverController;
  late Animation<double> _avatarHoverAnimation;

  late AnimationController _pipelineFlowController;

  @override
  void initState() {
    super.initState();

    // 1. Avatar Up-Down Bobbing Float Animation
    _avatarHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _avatarHoverAnimation = Tween<double>(begin: -6.0, end: 4.0).animate(
      CurvedAnimation(parent: _avatarHoverController, curve: Curves.easeInOut),
    );

    // 2. Neon Pipeline Energy Flow Animation
    _pipelineFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadStreakState();
  }

  @override
  void dispose() {
    _avatarHoverController.dispose();
    _pipelineFlowController.dispose();
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

    HapticFeedback.heavyImpact();
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
      _showCelebrationDialog(addedScore, cashBonus);
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

  void _showCelebrationDialog(int addedScore, double cashBonus) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66F59E0B),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Fire Trophy Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 38)),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'STAGE CLEARED!',
                style: TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Day $_currentStreak Strike Verified! Pawn advanced to next node.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),

              const SizedBox(height: 16),

              // Reward breakdown chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 5),
                        Text(
                          '+$addedScore Score Boost',
                          style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (cashBonus > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFBBF24), size: 16),
                          const SizedBox(width: 5),
                          Text(
                            '+₹$cashBonus Cash',
                            style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Task allocation prioritized your profile for higher-paying VIP tasks!',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                  ),
                  child: const Text(
                    'AWESOME! CONTINUE QUEST',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      backgroundColor: const Color(0xFF070B19), // Deep Cyber Gaming Navy
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B19),
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'STRIKE QUEST ROAD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(width: 6),
                Text('🗺️', style: TextStyle(fontSize: 15)),
              ],
            ),
            Text(
              '3D Level Road & Milestone Rewards',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66F59E0B),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 4),
                Text(
                  'DAY $_currentStreak / 7',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. 3D HERO STRIKE BANNER ──────────────────────────────────────────
              _buildHeroStrikeBanner(currentMultiplier),

              const SizedBox(height: 14),

              // ── 2. STRIKE GAINS & BENEFITS MATRIX ─────────────────────────────────
              _buildStrikeBenefitsStrip(),

              const SizedBox(height: 18),

              // ── 3. 3D GAME ROAD MAP (ZIG-ZAG NEON STAGES + AVATAR) ────────────────
              _buildRoadMapHeader(),

              const SizedBox(height: 10),

              _build3DGameRoadMap(),

              const SizedBox(height: 18),

              // ── 4. TACTILE 3D ARCADE CLAIM BUTTON ─────────────────────────────────
              _build3DTactileClaimButton(),

              const SizedBox(height: 20),

              // ── 5. GAMIFIED LEVEL PERKS ──────────────────────────────────────────
              const Row(
                children: [
                  Icon(Icons.military_tech_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Strike Perks & Super Powers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildPerksList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3D Hero Strike Banner ──────────────────────────────────────────────────
  Widget _buildHeroStrikeBanner(String currentMultiplier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4338CA), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334338CA),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 3D Glowing Animated Flame Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFDC2626)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                          ),
                          child: Text(
                            'TIER: $_workerTier',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                          ),
                          child: Text(
                            'SCORE: ${_workerScore.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_currentStreak DAY STRIKE ACTIVE! 🔥',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Daily presence unlocks priority tasks',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),

          // Speed Multiplier & Allocation Meter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: Color(0xFFFBBF24), size: 15),
                  const SizedBox(width: 4),
                  const Text('Task Speed: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    currentMultiplier,
                    style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF60A5FA)),
                    SizedBox(width: 3),
                    Text('VIP Priority', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Strike Benefits Strip ──────────────────────────────────────────────────
  Widget _buildStrikeBenefitsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131C31),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('Daily Strike', '+$_currentStreak Days', const Color(0xFFF59E0B)),
          Container(width: 1, height: 24, color: Colors.white12),
          _buildMiniStat('Score Boost', '+${_getScoreForDay(_currentStreak)} Pts', const Color(0xFF10B981)),
          Container(width: 1, height: 24, color: Colors.white12),
          _buildMiniStat('Task Speed', _getMultiplierForDay(_currentStreak), const Color(0xFF38BDF8)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Road Map Section Header ────────────────────────────────────────────────
  Widget _buildRoadMapHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Text('🎮', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text(
              '7-Day Quest Path',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _canClaimToday ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _canClaimToday ? const Color(0xFF10B981) : const Color(0xFF334155),
            ),
          ),
          child: Text(
            _canClaimToday ? 'Ready to Claim!' : 'Next: ${_formatTimer(_nextClaimRemaining)}',
            style: TextStyle(
              color: _canClaimToday ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── 3D Game Road Map (Zig-Zag S-Curve + Animated Pawn + Stage Disks) ───────
  Widget _build3DGameRoadMap() {
    // Stage configurations
    // Row 1: Day 1 (Left) -> Day 2 (Right)
    // Row 2: Day 3 (Left) -> Day 4 (Right)
    // Row 3: Day 5 (Left) -> Day 6 (Right)
    // Row 4: Day 7 (Grand Center Cyber Vault)
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const totalHeight = 440.0;

        // Coordinates of nodes for the canvas painter
        // Day 1 to Day 6 node center points
        final nodeCoords = [
          Offset(totalWidth * 0.22, 50),   // Day 1
          Offset(totalWidth * 0.78, 120),  // Day 2
          Offset(totalWidth * 0.22, 190),  // Day 3
          Offset(totalWidth * 0.78, 260),  // Day 4
          Offset(totalWidth * 0.22, 330),  // Day 5
          Offset(totalWidth * 0.78, 380),  // Day 6
        ];

        return Container(
          width: totalWidth,
          height: totalHeight + 100, // Extra space for Day 7 Grand Box
          decoration: BoxDecoration(
            color: const Color(0xFF0B1124),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Glowing Neon Energy Road (CustomPainter Background)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pipelineFlowController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _NeonRoadPainter(
                        nodes: nodeCoords,
                        currentStreak: _currentStreak,
                        flowProgress: _pipelineFlowController.value,
                        day7Anchor: Offset(totalWidth * 0.5, totalHeight + 20),
                      ),
                    );
                  },
                ),
              ),

              // 2. Stage Platforms for Day 1 to Day 6
              for (int i = 0; i < 6; i++)
                _buildStageNode(
                  dayNumber: i + 1,
                  center: nodeCoords[i],
                ),

              // 3. Floating 3D Worker Avatar Pawn (Hovering on current active stage)
              if (_currentStreak >= 1 && _currentStreak <= 6)
                _buildFloatingAvatarPawn(nodeCoords[_currentStreak - 1]),

              // 4. Day 7 Grand Mega Vault (At Road Bottom)
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: _buildDay7GrandBox(),
              ),

              // If Day 7 is current active streak, place Avatar right above Day 7 Box!
              if (_currentStreak == 7)
                Positioned(
                  bottom: 85,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildAvatarWidget(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Stage Node (3D Isometric Platform Disk) ────────────────────────────────
  Widget _buildStageNode({
    required int dayNumber,
    required Offset center,
  }) {
    const nodeWidth = 96.0;
    const nodeHeight = 58.0;

    final isPassed = dayNumber < _currentStreak;
    final isCurrent = dayNumber == _currentStreak;

    Color topColor = const Color(0xFF1E293B);
    Color bottomDepthColor = const Color(0xFF0F172A);
    Color borderColor = const Color(0xFF334155);

    if (isPassed) {
      topColor = const Color(0xFF065F46);
      bottomDepthColor = const Color(0xFF064E3B);
      borderColor = const Color(0xFF10B981);
    } else if (isCurrent) {
      topColor = const Color(0xFFD97706);
      bottomDepthColor = const Color(0xFF92400E);
      borderColor = const Color(0xFFFDE047);
    }

    return Positioned(
      left: center.dx - (nodeWidth / 2),
      top: center.dy - (nodeHeight / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Isometric Platform Disk
          Container(
            width: nodeWidth,
            height: nodeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [topColor, bottomDepthColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? const Color(0xFFF59E0B).withOpacity(0.4)
                      : (isPassed ? const Color(0xFF10B981).withOpacity(0.25) : Colors.black.withOpacity(0.3)),
                  blurRadius: isCurrent ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day Tag
                Text(
                  'DAY $dayNumber',
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFFFEF08A) : (isPassed ? const Color(0xFF6EE7B7) : Colors.white70),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                // Center Icon + Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isPassed
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14)
                        : Text(
                            dayNumber % 2 == 0 ? '⚡' : '🔥',
                            style: const TextStyle(fontSize: 13),
                          ),
                    const SizedBox(width: 3),
                    Text(
                      '+${_getScoreForDay(dayNumber)}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : (isPassed ? const Color(0xFFA7F3D0) : Colors.white70),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                // Speed Mult
                Text(
                  _getMultiplierForDay(dayNumber),
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFFFEF3C7) : const Color(0xFF94A3B8),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating 3D Worker Avatar Pawn ─────────────────────────────────────────
  Widget _buildFloatingAvatarPawn(Offset nodeCenter) {
    return Positioned(
      left: nodeCenter.dx - 32,
      top: nodeCenter.dy - 68,
      child: AnimatedBuilder(
        animation: _avatarHoverAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _avatarHoverAnimation.value),
            child: child,
          );
        },
        child: _buildAvatarWidget(),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "YOU" Player Tag Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66F59E0B),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'YOU',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 2),

        // 3D Glowing Worker Character Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1E3A8A)],
            ),
            border: Border.all(color: const Color(0xFF93C5FD), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.7),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('👷', style: TextStyle(fontSize: 18)),
          ),
        ),

        // Pointer Arrow pointing down to platform
        const Icon(Icons.arrow_drop_down, color: Color(0xFF60A5FA), size: 14),
      ],
    );
  }

  // ── Day 7 Grand Mega Vault (Final Road Island) ──────────────────────────────
  Widget _buildDay7GrandBox() {
    final isDay7 = _currentStreak == 7;
    final isPassed = _currentStreak > 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDay7 ? const Color(0xFFF59E0B) : const Color(0xFFA855F7),
          width: isDay7 ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing Diamond Sphere
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFE879F9), Color(0xFFA855F7), Color(0xFF6B21A8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.6),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: isPassed
                  ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22)
                  : const Text('💎', style: TextStyle(fontSize: 22)),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DAY 7 • GRAND MEGA VAULT',
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                      ),
                      child: const Text('VIP', style: TextStyle(color: Color(0xFFFDE047), fontSize: 8.5, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '+150 Quality Score • ₹25 Instant Wallet Bonus',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Speed Multiplier Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA855F7)),
            ),
            child: const Text(
              '1.50x Boost',
              style: TextStyle(color: Color(0xFFE9D5FF), fontWeight: FontWeight.w900, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tactile 3D Arcade Claim Button (Physically Sinks on Tap) ────────────────
  Widget _build3DTactileClaimButton() {
    final canClaim = _canClaimToday && !_isClaiming;
    final buttonOffset = _isButtonPressed ? 4.0 : 0.0;
    final shadowHeight = _isButtonPressed ? 0.0 : 5.0;

    return GestureDetector(
      onTapDown: canClaim ? (_) => setState(() => _isButtonPressed = true) : null,
      onTapUp: canClaim ? (_) {
        setState(() => _isButtonPressed = false);
        _claimStreakBonus();
      } : null,
      onTapCancel: canClaim ? () => setState(() => _isButtonPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(0, buttonOffset, 0),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: canClaim ? const Color(0xFFD97706) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (canClaim)
              BoxShadow(
                color: const Color(0xFFB45309),
                offset: Offset(0, shadowHeight),
                blurRadius: 0,
              ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.only(bottom: shadowHeight),
          decoration: BoxDecoration(
            gradient: canClaim
                ? const LinearGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: canClaim ? const Color(0xFFFEF08A) : const Color(0xFF334155),
              width: 1.2,
            ),
          ),
          child: Center(
            child: _isClaiming
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2.2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canClaim ? Icons.local_fire_department_rounded : Icons.timer_outlined,
                        color: canClaim ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        canClaim
                            ? 'CLAIM DAY $_currentStreak STRIKE (+${_getScoreForDay(_currentStreak)} PTS)'
                            : 'STREAK SECURED • NEXT IN ${_formatTimer(_nextClaimRemaining)}',
                        style: TextStyle(
                          color: canClaim ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Gamified Perks List ────────────────────────────────────────────────────
  Widget _buildPerksList() {
    final perks = [
      {
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF38BDF8),
        'title': 'Priority Task Dispatch',
        'desc': 'High-streak workers receive newly posted tasks first.',
      },
      {
        'icon': Icons.stars_rounded,
        'color': const Color(0xFFF59E0B),
        'title': 'Quality Score Boost',
        'desc': 'Daily presence permanently builds your reputation trust score.',
      },
      {
        'icon': Icons.diamond_rounded,
        'color': const Color(0xFFA855F7),
        'title': 'VIP Campaign Access',
        'desc': 'Unlocks high-payout premium tasks at higher streak levels.',
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'color': const Color(0xFF10B981),
        'title': 'Day 7 Cash Bonus',
        'desc': 'Complete all 7 days to get ₹25 bonus cash directly.',
      },
    ];

    return Column(
      children: perks.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF131C31),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (p['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['title'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      p['desc'] as String,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// ── Custom Painter: S-Curve Neon Road Pipeline with Energy Pulse ────────────
class _NeonRoadPainter extends CustomPainter {
  final List<Offset> nodes;
  final int currentStreak;
  final double flowProgress;
  final Offset day7Anchor;

  _NeonRoadPainter({
    required this.nodes,
    required this.currentStreak,
    required this.flowProgress,
    required this.day7Anchor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 6) return;

    final path = Path();
    path.moveTo(nodes[0].dx, nodes[0].dy);

    for (int i = 0; i < nodes.length - 1; i++) {
      final p0 = nodes[i];
      final p1 = nodes[i + 1];
      final midY = (p0.dy + p1.dy) / 2;

      path.cubicTo(
        p0.dx, midY, // Control point 1
        p1.dx, midY, // Control point 2
        p1.dx, p1.dy, // End point
      );
    }

    // Connect node 6 to Day 7 Anchor
    final lastNode = nodes.last;
    final finalMidY = (lastNode.dy + day7Anchor.dy) / 2;
    path.cubicTo(
      lastNode.dx, finalMidY,
      day7Anchor.dx, finalMidY,
      day7Anchor.dx, day7Anchor.dy,
    );

    // 1. Outer Dark Rail Background
    final railPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, railPaint);

    // 2. Wide Neon Glow Layer
    final glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFA855F7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // 3. Inner Laser Core
    final laserPaint = Paint()
      ..color = const Color(0xFF67E8F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, laserPaint);

    // 4. Traveling Energy Sparks (Light Pulse along path)
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLen = metric.length;

      for (int spark = 0; spark < 3; spark++) {
        final sparkOffset = (flowProgress * totalLen + (spark * (totalLen / 3))) % totalLen;
        final tangent = metric.getTangentForOffset(sparkOffset);

        if (tangent != null) {
          final sparkPaint = Paint()
            ..color = const Color(0xFFFDE047)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawCircle(tangent.position, 4.5, sparkPaint);

          final coreSparkPaint = Paint()..color = Colors.white;
          canvas.drawCircle(tangent.position, 2.2, coreSparkPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeonRoadPainter oldDelegate) {
    return oldDelegate.flowProgress != flowProgress ||
           oldDelegate.currentStreak != currentStreak;
  }
}
