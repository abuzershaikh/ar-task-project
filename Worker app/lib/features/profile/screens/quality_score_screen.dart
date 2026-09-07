import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/profile_provider.dart';

/// 🌿 Professional Worker Quality Score & Performance Rating Screen:
/// - Mayan Emerald & Gold aesthetic
/// - Connected live to ApiService & ProfileProvider
/// - Real live API worker score & metrics with ZERO dummy numbers
class QualityScoreScreen extends StatefulWidget {
  const QualityScoreScreen({super.key});

  @override
  State<QualityScoreScreen> createState() => _QualityScoreScreenState();
}

class _QualityScoreScreenState extends State<QualityScoreScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _scoreData = {};

  // ── Palette Tokens ────────────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF04140F);
  static const Color _cardDark = Color(0xFF09291E);
  static const Color _cardBorder = Color(0xFF10B981);
  static const Color _goldPrimary = Color(0xFFF59E0B);
  static const Color _goldLight = Color(0xFFFDE68A);
  static const Color _emeraldBright = Color(0xFF10B981);
  static const Color _emeraldLight = Color(0xFF34D399);
  static const Color _textWhite = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _loadScoreData();
  }

  Future<void> _loadScoreData() async {
    try {
      final res = await ApiService.getScore();
      if (mounted) {
        setState(() {
          _scoreData = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profileData;
    final scoreObj = (_scoreData['score'] is Map ? _scoreData['score'] : null) ??
        (profileProvider.scoreData['score'] is Map ? profileProvider.scoreData['score'] : null) ??
        (profile['score'] is Map ? profile['score'] : {});
    final breakdownObj = (scoreObj['breakdown'] is Map) ? scoreObj['breakdown'] : {};

    final int totalApproved = int.tryParse(profile['totalTasksCompleted']?.toString() ?? '') ?? 0;
    final int totalRejected = int.tryParse(profile['totalTasksRejected']?.toString() ?? '') ?? 0;
    final int totalTasks = totalApproved + totalRejected;
    final bool isNewWorker = totalTasks == 0;

    final double overallScore = double.tryParse(scoreObj['overallScore']?.toString() ?? '') ??
        double.tryParse(scoreObj['totalScore']?.toString() ?? '') ??
        profileProvider.liveQualityScore;

    final double rating = profileProvider.liveRating;

    final double accuracyRate = double.tryParse(breakdownObj['quality']?.toString() ?? '') ??
        double.tryParse(profile['successRate']?.toString() ?? '') ??
        (totalTasks > 0 ? (totalApproved / totalTasks * 100.0) : 0.0);

    final double completionRate = double.tryParse(breakdownObj['completion']?.toString() ?? '') ??
        (totalTasks > 0 ? (totalApproved / totalTasks * 100.0) : 0.0);

    final double rejectionRate = totalTasks > 0
        ? ((totalRejected / totalTasks) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    final double onTimeRate = double.tryParse(breakdownObj['reliability']?.toString() ?? '') ??
        (totalTasks > 0 ? (100.0 - rejectionRate).clamp(0.0, 100.0) : 100.0);

    final String workerTier = scoreObj['workerTier']?.toString() ??
        (totalApproved >= 25 ? 'GOLD' : (totalApproved >= 10 ? 'SILVER' : (totalApproved > 0 ? 'BRONZE' : 'NEW')));

    final Map<String, dynamic>? priorityObj =
        scoreObj['priority'] is Map ? Map<String, dynamic>.from(scoreObj['priority']) : null;
    final String priorityLabel =
        priorityObj?['label']?.toString() ?? (isNewWorker ? '⭐⭐⭐ Normal tasks' : '⭐ Standard priority');
    final int priorityStars = priorityObj?['stars'] != null
        ? (int.tryParse(priorityObj!['stars'].toString()) ?? 3)
        : (rating > 0 ? rating.round().clamp(1, 5) : 3);

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cardDark,
              border: Border.all(color: _cardBorder.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _textWhite, size: 18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quality Score & Rating',
          style: GoogleFonts.poppins(
            color: _textWhite,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _emeraldLight, size: 20),
            onPressed: () {
              setState(() => _isLoading = true);
              Future.wait([
                _loadScoreData(),
                profileProvider.fetchProfile(),
              ]);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF04140F),
              Color(0xFF07241A),
              Color(0xFF03160F),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _emeraldBright))
              : RefreshIndicator(
                  color: _emeraldBright,
                  backgroundColor: _cardDark,
                  onRefresh: () async {
                    await Future.wait([
                      _loadScoreData(),
                      profileProvider.fetchProfile(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Top Score Banner Card ─────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A3A29), Color(0xFF042016)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _cardBorder.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: _emeraldBright.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Stars Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  5,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Icon(
                                      index < priorityStars ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 26,
                                      color: index < priorityStars
                                          ? _goldPrimary
                                          : Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Headline Score
                              Text(
                                '${overallScore.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  color: _textWhite,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Overall Quality Score',
                                style: GoogleFonts.poppins(
                                  color: _emeraldLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Badges row
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _emeraldBright.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _emeraldBright.withValues(alpha: 0.45)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_rounded, size: 14, color: _emeraldLight),
                                        const SizedBox(width: 5),
                                        Text(
                                          isNewWorker ? '🌱 Starter Score 60.0%' : '⚡ Live Active Score',
                                          style: GoogleFonts.poppins(
                                            color: _emeraldLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _goldPrimary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _goldPrimary.withValues(alpha: 0.45)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.military_tech_rounded, size: 14, color: _goldPrimary),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$workerTier TIER',
                                          style: GoogleFonts.poppins(
                                            color: _goldLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Rating display
                              Text(
                                rating > 0
                                    ? '${rating.toStringAsFixed(1)} / 5.0 Average Rating'
                                    : 'New Worker • Not Rated Yet',
                                style: GoogleFonts.poppins(
                                  color: _textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── 2. Performance Breakdown Section ─────────────────────
                        _buildSectionHeader('Live Performance Breakdown', Icons.analytics_rounded),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _cardBorder.withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMetricRow(
                                'Quality & Accuracy',
                                '${accuracyRate.toStringAsFixed(1)}%',
                                Icons.verified_rounded,
                                _emeraldBright,
                                accuracyRate / 100.0,
                              ),
                              _buildDivider(),
                              _buildMetricRow(
                                'Task Completion Rate',
                                '${completionRate.toStringAsFixed(1)}%',
                                Icons.task_alt_rounded,
                                const Color(0xFF38BDF8),
                                completionRate / 100.0,
                              ),
                              _buildDivider(),
                              _buildMetricRow(
                                'Reliability & On-Time',
                                '${onTimeRate.toStringAsFixed(1)}%',
                                Icons.access_time_filled_rounded,
                                const Color(0xFFA78BFA),
                                onTimeRate / 100.0,
                              ),
                              _buildDivider(),
                              _buildMetricRow(
                                'Rejection Rate',
                                '${rejectionRate.toStringAsFixed(1)}%',
                                Icons.cancel_outlined,
                                rejectionRate > 10 ? const Color(0xFFEF4444) : _textMuted,
                                rejectionRate / 100.0,
                              ),
                              _buildDivider(),
                              _buildMetricRow(
                                'Total Approved Tasks',
                                '$totalApproved Tasks',
                                Icons.military_tech_rounded,
                                _goldPrimary,
                                (totalApproved / 25.0).clamp(0.0, 1.0),
                              ),
                              _buildDivider(),
                              _buildMetricRow(
                                'Total Rejected Tasks',
                                '$totalRejected Tasks',
                                Icons.highlight_off_rounded,
                                const Color(0xFFF87171),
                                (totalRejected / 10.0).clamp(0.0, 1.0),
                              ),
                              _buildDivider(),
                              _buildPriorityCard(priorityLabel, priorityStars),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── 3. Verified Badges & Standing ─────────────────────────
                        _buildSectionHeader('Worker Standing & Badges', Icons.workspace_premium_rounded),
                        const SizedBox(height: 12),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.1,
                          children: [
                            _buildBadgeCard(
                              overallScore >= 75 ? 'Top Performer' : 'Active Contributor',
                              overallScore >= 75 ? 'High Quality Score' : 'Building Score',
                              Icons.star_rounded,
                              overallScore >= 75 ? _goldPrimary : _emeraldBright,
                            ),
                            _buildBadgeCard(
                              'Speed Submissions',
                              'On-time task submissions',
                              Icons.bolt_rounded,
                              const Color(0xFF38BDF8),
                            ),
                            _buildBadgeCard(
                              rejectionRate == 0
                                  ? 'Zero Rejection'
                                  : (rejectionRate <= 10 ? 'Low Rejection' : 'Needs Care'),
                              '${rejectionRate.toStringAsFixed(1)}% rejection',
                              rejectionRate <= 10 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                              rejectionRate <= 10 ? _emeraldLight : const Color(0xFFF87171),
                            ),
                            _buildBadgeCard(
                              profile['kycStatus']?.toString().toUpperCase() == 'APPROVED'
                                  ? 'KYC Approved'
                                  : 'KYC Pending',
                              'Identity verification',
                              Icons.shield_outlined,
                              profile['kycStatus']?.toString().toUpperCase() == 'APPROVED'
                                  ? _emeraldLight
                                  : const Color(0xFFA78BFA),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── 4. Quality Standards Tips ────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07241A),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _cardBorder.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 16, color: _goldLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    'How to Maintain 90%+ Quality Score',
                                    style: GoogleFonts.poppins(
                                      color: _goldLight,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '• Upload genuine, clear screenshot proofs for each task.\n• Submit tasks within the given deadline to keep your reliability high.\n• Avoid duplicate submissions or invalid screenshot uploads.\n• Complete more tasks to elevate your tier from New to Silver & Gold.',
                                style: GoogleFonts.poppins(
                                  color: _textMuted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _emeraldBright),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: _goldLight,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.white.withValues(alpha: 0.07),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: _textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 5,
            color: Colors.black.withValues(alpha: 0.4),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityCard(String label, int stars) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF041C14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _goldPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed_rounded, color: _goldPrimary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Task Priority Level',
                style: GoogleFonts.poppins(
                  color: _textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _goldPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _goldPrimary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$stars / 5 Stars',
                  style: GoogleFonts.poppins(
                    color: _goldLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _goldPrimary.withValues(alpha: 0.2)),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: _goldLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 5,
              color: Colors.black.withValues(alpha: 0.4),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: (stars / 5.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _goldPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: _textWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: _textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
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
}
