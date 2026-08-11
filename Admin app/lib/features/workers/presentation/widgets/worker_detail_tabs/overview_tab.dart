import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class OverviewTab extends StatelessWidget {
  final String workerId;

  const OverviewTab({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Meta Card
          _buildCard(
            'Account Information',
            [
              _buildInfoRow('Status', 'ACTIVE', AppColors.success),
              _buildInfoRow('Joined Date', '15 Jan 2024', AppColors.gray700),
              _buildInfoRow('Last Active', '2 hours ago', AppColors.gray700),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Performance Metrics Card
          _buildCard(
            'Performance Metrics',
            [
              _buildMetricRow('Rating', '⭐ 4.8', AppColors.warning),
              _buildMetricRow('Quality Score', '92.5', AppColors.primary),
              _buildMetricRow('Completion Rate', '96%', AppColors.success),
              _buildMetricRow('Acceptance Rate', '94%', AppColors.success),
              _buildMetricRow('Timeout Rate', '2%', AppColors.error),
              _buildMetricRow('Rejection Rate', '3%', AppColors.error),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Task Totals Card
          _buildCard(
            'Task Summary',
            [
              _buildTaskStat('Total Tasks', '1,245', Icons.task, AppColors.primary),
              _buildTaskStat('Completed', '1,180', Icons.check_circle, AppColors.success),
              _buildTaskStat('In Progress', '12', Icons.pending, AppColors.warning),
              _buildTaskStat('Rejected', '20', Icons.cancel, AppColors.error),
              _buildTaskStat('Timed Out', '33', Icons.timer_off, AppColors.error),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.pause_circle, size: 18),
                  label: const Text('Suspend'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Ban'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStat(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
