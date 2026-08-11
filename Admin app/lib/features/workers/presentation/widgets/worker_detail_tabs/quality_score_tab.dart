import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class QualityScoreTab extends StatelessWidget {
  final String workerId;

  const QualityScoreTab({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Overall Quality Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '92.5',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Text(
                      'EXCELLENT PERFORMER',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Score Components
          const Text(
            'Score Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildScoreComponent('Reliability', 95, AppColors.success),
          _buildScoreComponent('Completion Rate', 96, AppColors.success),
          _buildScoreComponent('Rating', 94, AppColors.warning),
          _buildScoreComponent('Experience', 85, AppColors.info),
          _buildScoreComponent('Consistency', 91, AppColors.primary),
          
          const SizedBox(height: 24),
          
          // Historical Trend
          const Text(
            'Score History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScoreHistoryItem('Today', '92.5', AppColors.primary, true),
                  _buildScoreHistoryItem('Yesterday', '92.3', AppColors.primary, false),
                  _buildScoreHistoryItem('2 days ago', '91.8', AppColors.primary, false),
                  _buildScoreHistoryItem('3 days ago', '91.5', AppColors.primary, false),
                  _buildScoreHistoryItem('4 days ago', '91.2', AppColors.primary, false),
                  _buildScoreHistoryItem('5 days ago', '90.8', AppColors.primary, false),
                  _buildScoreHistoryItem('6 days ago', '90.5', AppColors.primary, false),
                  _buildScoreHistoryItem('1 week ago', '90.0', AppColors.primary, false),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Score Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quality score is calculated based on reliability, completion rate, ratings, experience, and consistency metrics.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.info.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComponent(String label, int score, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  '$score / 100',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor: AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHistoryItem(String date, String score, Color color, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isCurrent)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  color: isCurrent ? AppColors.gray900 : AppColors.gray600,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            score,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
