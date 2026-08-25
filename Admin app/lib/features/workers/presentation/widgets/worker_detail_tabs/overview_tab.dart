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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Meta Card
          _buildCard(
            'Account & Identity',
            Icons.person_pin_rounded,
            [
              _buildInfoRow('Full Name', worker.name, const Color(0xFF0F172A)),
              _buildInfoRow('Email Address', worker.email, const Color(0xFF0F172A)),
              _buildInfoRow('Phone Number', worker.phone.isNotEmpty ? worker.phone : 'Not Provided', const Color(0xFF64748B)),
              _buildInfoRow('Account Status', worker.status, worker.status == 'ACTIVE' ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
              _buildInfoRow('KYC Verification', worker.kycStatus, (worker.kycStatus == 'VERIFIED' || worker.kycStatus == 'APPROVED') ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
              _buildInfoRow('Registration Date', joinedDate, const Color(0xFF64748B)),
              _buildInfoRow('Worker UID', worker.userId.isNotEmpty ? worker.userId : worker.id, const Color(0xFF0284C7)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Performance Metrics Card
          _buildCard(
            'Performance Metrics',
            Icons.insights_rounded,
            [
              _buildMetricRow('Rating Score', '⭐ ${worker.rating.toStringAsFixed(1)} / 5.0', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
              _buildMetricRow('Performance Tier', worker.tier, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
              _buildMetricRow('Total Earnings Recorded', '₹${worker.totalEarnings.toStringAsFixed(2)}', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Task Totals Card
          _buildCard(
            'Task Operations Summary',
            Icons.task_alt_rounded,
            [
              _buildTaskStat('Tasks Completed', '${worker.completedTasks}', Icons.task_rounded, const Color(0xFF0284C7)),
              _buildTaskStat('Active & Recorded Records', '${tasks.length}', Icons.check_circle_rounded, const Color(0xFF16A34A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
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
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3), width: 0.8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Text(
            value,
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

