import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/worker_model.dart';

class OverviewTab extends StatelessWidget {
  final WorkerModel worker;
  final List<dynamic> tasks;
  final List<dynamic> earnings;

  const OverviewTab({
    super.key,
    required this.worker,
    this.tasks = const [],
    this.earnings = const [],
  });

  @override
  Widget build(BuildContext context) {
    final joinedDate = worker.createdAt != null
        ? '${worker.createdAt!.day}/${worker.createdAt!.month}/${worker.createdAt!.year}'
        : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Meta Card
          _buildCard(
            'Account Information',
            [
              _buildInfoRow('Name', worker.name, AppColors.gray900),
              _buildInfoRow('Email', worker.email, AppColors.gray900),
              _buildInfoRow('Phone', worker.phone.isNotEmpty ? worker.phone : 'N/A', AppColors.gray700),
              _buildInfoRow('Status', worker.status, worker.status == 'ACTIVE' ? AppColors.success : AppColors.error),
              _buildInfoRow('KYC Status', worker.kycStatus, worker.kycStatus == 'VERIFIED' ? AppColors.success : AppColors.warning),
              _buildInfoRow('Joined Date', joinedDate, AppColors.gray700),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Performance Metrics Card
          _buildCard(
            'Performance Metrics',
            [
              _buildMetricRow('Rating', '⭐ ${worker.rating.toStringAsFixed(1)}', AppColors.warning),
              _buildMetricRow('Tier', worker.tier, AppColors.primary),
              _buildMetricRow('Total Earnings', '₹${worker.totalEarnings.toStringAsFixed(2)}', AppColors.success),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Task Totals Card
          _buildCard(
            'Task Summary',
            [
              _buildTaskStat('Completed Tasks', '${worker.completedTasks}', Icons.task, AppColors.primary),
              _buildTaskStat('Recorded Tasks', '${tasks.length}', Icons.check_circle, AppColors.success),
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
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
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
