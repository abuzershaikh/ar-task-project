import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/campaign_detail.dart';

class OverviewTab extends StatelessWidget {
  final CampaignDetail campaign;

  const OverviewTab({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Card
          _ProgressCard(campaign: campaign),
          const SizedBox(height: 12),

          // Campaign Details
          _DetailsCard(campaign: campaign),
          const SizedBox(height: 12),

          // Deadline Status
          if (campaign.hasExtensions) ...[
            _DeadlineCard(campaign: campaign),
            const SizedBox(height: 12),
          ],

          // Performance Metrics
          _MetricsCard(campaign: campaign),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CampaignDetail campaign;

  const _ProgressCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final double progress = campaign.completionPercentage / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'Task Completion Progress',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${campaign.completedTasks} / ${campaign.totalTasks} Tasks',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(campaign.completionPercentage),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${campaign.totalTasks - campaign.completedTasks} tasks remaining',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              Text(
                '${campaign.completionPercentage.toStringAsFixed(1)}% Complete',
                style: TextStyle(
                  fontSize: 11,
                  color: _getProgressColor(campaign.completionPercentage),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Task Status 4-Grid
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  label: 'Completed',
                  value: campaign.completedTasks,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusItem(
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  label: 'In Progress',
                  value: campaign.inProgressTasks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                  label: 'Pending',
                  value: campaign.pendingTasks,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusItem(
                  icon: Icons.cancel_rounded,
                  iconColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                  label: 'Rejected',
                  value: campaign.rejectedTasks,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 50) return const Color(0xFF2563EB);
    if (percentage >= 25) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final int value;

  const _StatusItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF64748B),
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

class _DetailsCard extends StatelessWidget {
  final CampaignDetail campaign;

  const _DetailsCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Campaign Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _DetailRow('Service Type', campaign.serviceName),
          _DetailRow('Status', campaign.status.toUpperCase()),
          _DetailRow('Created', timeago.format(campaign.createdAt)),
          if (campaign.currentDeadline != null)
            _DetailRow(
              'Deadline',
              '${campaign.currentDeadline!.day} ${_getMonthName(campaign.currentDeadline!.month)}, ${_formatTime(campaign.currentDeadline!)}',
            ),
          if (campaign.remainingTime != null)
            _DetailRow('Remaining Time', campaign.remainingTime!),

          const Divider(height: 18, color: Color(0xFFF1F5F9)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Campaign Budget',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              Text(
                CurrencyFormatter.formatINR(campaign.totalAmount),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}

class _DeadlineCard extends StatelessWidget {
  final CampaignDetail campaign;

  const _DeadlineCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 16),
              SizedBox(width: 6),
              Text(
                'Deadline Extensions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (campaign.extensions != null)
            ...campaign.extensions!.map((extension) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              extension.reason,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF78350F),
                              ),
                            ),
                            Text(
                              'Extended by ${extension.extensionHours} hours',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final CampaignDetail campaign;

  const _MetricsCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.query_stats_rounded, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Approval Rate',
                  value: '${campaign.approvalRate.toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricItem(
                  label: 'Rejection Rate',
                  value: '${campaign.rejectionRate.toStringAsFixed(1)}%',
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Avg Review Time',
                  value: '${campaign.averageReviewTimeMinutes} min',
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricItem(
                  label: 'Pending Reviews',
                  value: campaign.pendingReviews.toString(),
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
