import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/profile_provider.dart';

/// Dedicated Worker Quality Score & Rating Screen (Connected to ApiService)
class QualityScoreScreen extends StatefulWidget {
  const QualityScoreScreen({super.key});

  @override
  State<QualityScoreScreen> createState() => _QualityScoreScreenState();
}

class _QualityScoreScreenState extends State<QualityScoreScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _scoreData = {};

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
    final scoreObj = _scoreData['score'] ?? {};
    final breakdownObj = scoreObj['breakdown'] ?? {};

    final rating = (breakdownObj['rating'] ?? 4.9).toDouble();
    final accuracyRate = (breakdownObj['quality'] ?? 98.5).toDouble();
    final onTimeRate = (breakdownObj['reliability'] ?? 99.2).toDouble();
    final totalApproved = (profileProvider.profileData['totalTasksCompleted'] ?? 42).toInt();
    final rejectionRate = (100.0 - accuracyRate).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quality Score & Rating',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00875A)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => const Icon(
                                Icons.star_rounded,
                                size: 28,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${rating.toStringAsFixed(1)} / 5.0 Rating',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🏆 Quality Score: ${accuracyRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Breakdown Card
                    const Text(
                      'Performance Breakdown',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow(
                            'Task Approval Rate',
                            '${accuracyRate.toStringAsFixed(1)}%',
                            Icons.task_alt_rounded,
                            const Color(0xFF00875A),
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildMetricRow(
                            'Rejection Rate',
                            '${rejectionRate.toStringAsFixed(1)}%',
                            Icons.cancel_outlined,
                            const Color(0xFFDC2626),
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildMetricRow(
                            'On-Time Submission',
                            '${onTimeRate.toStringAsFixed(1)}%',
                            Icons.access_time_filled_rounded,
                            const Color(0xFF0284C7),
                          ),
                          const Divider(height: 24, color: Color(0xFFE2E8F0)),
                          _buildMetricRow(
                            'Total Approved Tasks',
                            '$totalApproved Tasks',
                            Icons.verified_rounded,
                            const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Achievement Badges Section
                    const Text(
                      'Badges Earned',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _buildBadgeCard('Top Performer', '🌟 High Rating', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                        _buildBadgeCard('Speedy Finisher', '⚡ Fast Submits', const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                        _buildBadgeCard('100% Accuracy', '🎯 Zero Errors', const Color(0xFFE6F4EA), const Color(0xFF00875A)),
                        _buildBadgeCard('Trusted Worker', '🛡️ KYC Verified', const Color(0xFFF1F5F9), const Color(0xFF475569)),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(String title, String subtitle, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
