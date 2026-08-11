import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ActivityTab extends StatelessWidget {
  final String workerId;

  const ActivityTab({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return _buildActivityItem(index);
      },
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {'type': 'login', 'text': 'Worker logged in', 'icon': Icons.login, 'color': AppColors.info},
      {'type': 'task_accept', 'text': 'Task accepted (T-10001)', 'icon': Icons.check_circle, 'color': AppColors.success},
      {'type': 'proof', 'text': 'Proof submitted (T-10001)', 'icon': Icons.upload, 'color': AppColors.warning},
      {'type': 'approved', 'text': 'Task approved (T-10001)', 'icon': Icons.verified, 'color': AppColors.success},
      {'type': 'earning', 'text': 'Earning posted ₹15', 'icon': Icons.currency_rupee, 'color': AppColors.primary},
    ];
    
    final activity = activities[index % activities.length];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 20,
          ),
        ),
        title: Text(
          activity['text'] as String,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getTimeAgo(index),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(int index) {
    if (index == 0) return 'Just now';
    if (index < 5) return '${index * 2} minutes ago';
    if (index < 10) return '${index} hours ago';
    return '${index - 9} days ago';
  }
}
