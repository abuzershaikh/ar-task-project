import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('Total Tasks', '5,000', Icons.task_outlined, AppColors.primary),
          const SizedBox(height: 12),
          _buildStatCard('Completed', '4,320', Icons.check_circle, AppColors.success),
          const SizedBox(height: 12),
          _buildStatCard('Pending', '420', Icons.pending, AppColors.warning),
          const SizedBox(height: 12),
          _buildStatCard('Rejected', '160', Icons.cancel, AppColors.error),
          const SizedBox(height: 24),
          Text('Charts coming soon...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.statNumber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
