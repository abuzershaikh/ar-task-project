import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/worker_model.dart';

class QualityScoreTab extends StatelessWidget {
  final WorkerModel worker;
  final Map<String, dynamic> scoreHistory;

  const QualityScoreTab({
    super.key,
    required this.worker,
    this.scoreHistory = const {},
  });

  @override
  Widget build(BuildContext context) {
    final double scoreValue = worker.score > 0 ? worker.score : (worker.rating * 20).clamp(0.0, 100.0);
    final qualityScore = scoreValue.toStringAsFixed(1);

    final String badgeText;
    final Color badgeColor;
    final Color badgeBg;
    if (worker.status.toUpperCase() == 'BANNED' || worker.status.toUpperCase() == 'SUSPENDED') {
      badgeText = 'Account Restricted / Quality Suspended 🔴';
      badgeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
    } else if (scoreValue >= 85) {
      badgeText = 'Top Performer & Elite Quality 🟢';
      badgeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
    } else if (scoreValue >= 70) {
      badgeText = 'Good Standing & Verified Quality 🟡';
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
    } else {
      badgeText = 'Under Quality Monitoring 🟠';
      badgeColor = const Color(0xFFEA580C);
      badgeBg = const Color(0xFFFFEDD5);
    }

    // Dynamic quality parameters based on real worker metrics
    final double accuracyRate = (worker.rating / 5.0).clamp(0.0, 1.0);
    final double turnaroundSpeed = worker.tier == 'Gold'
        ? 0.96
        : (worker.tier == 'Silver'
            ? 0.88
            : (worker.tier == 'Bronze' ? 0.78 : (worker.completedTasks > 0 ? 0.72 : 0.60)));
    final double compliance = worker.status.toUpperCase() == 'ACTIVE'
        ? 1.0
        : (worker.status.toUpperCase() == 'SUSPENDED' ? 0.50 : 0.10);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080284C7),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Overall Worker Quality Index',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    qualityScore,
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                  const Text(
                    '/ 100 Quality Points',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Performance Metrics
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080284C7),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text(
                        'Quality Parameters',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildMetricProgress('Approval Accuracy Rate', accuracyRate, '${(accuracyRate * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 10),
                  _buildMetricProgress('Task Turnaround Speed', turnaroundSpeed, '${(turnaroundSpeed * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 10),
                  _buildMetricProgress('Platform Compliance', compliance, '${(compliance * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricProgress(String label, double value, String display) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            Text(display, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: const Color(0xFFE0F2FE),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
