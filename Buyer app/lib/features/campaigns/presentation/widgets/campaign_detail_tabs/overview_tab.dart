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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Card
          _ProgressCard(campaign: campaign),
          const SizedBox(height: 16),

          // Campaign Details
          _DetailsCard(campaign: campaign),
          const SizedBox(height: 16),

          // Deadline Status
          if (campaign.hasExtensions) ...[
            _DeadlineCard(campaign: campaign),
            const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${campaign.completedTasks} / ${campaign.totalTasks}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: campaign.completionPercentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(campaign.completionPercentage),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${campaign.completionPercentage.toStringAsFixed(1)}% Complete',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Task Status Grid
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  label: 'Completed',
                  value: campaign.completedTasks,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: Icons.pending,
                  iconColor: Colors.blue,
                  label: 'In Progress',
                  value: campaign.inProgressTasks,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: Icons.circle_outlined,
                  iconColor: Colors.grey,
                  label: 'Pending',
                  value: campaign.pendingTasks,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: Icons.cancel,
                  iconColor: Colors.red,
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
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.blue;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;

  const _StatusItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _DetailRow('Service', campaign.serviceName),
          _DetailRow('Status', campaign.status.toUpperCase()),
          _DetailRow('Created', timeago.format(campaign.createdAt)),
          if (campaign.currentDeadline != null)
            _DetailRow(
              'Deadline',
              '${campaign.currentDeadline!.day} ${_getMonthName(campaign.currentDeadline!.month)}, ${_formatTime(campaign.currentDeadline!)}',
            ),
          if (campaign.remainingTime != null)
            _DetailRow('Remaining', campaign.remainingTime!),
          
          const Divider(height: 24),
          
          const Text(
            'Campaign Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          _DetailRow('Total', CurrencyFormatter.formatINR(campaign.totalAmount)),
          _DetailRow('Payment', campaign.paymentStatus.toUpperCase()),
        ],
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Deadline History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (campaign.extensions != null)
            ...campaign.extensions!.map((extension) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extension.reason,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Extended by ${extension.extensionHours} hours',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Approval Rate',
                  value: '${campaign.approvalRate.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricItem(
                  label: 'Rejection Rate',
                  value: '${campaign.rejectionRate.toStringAsFixed(1)}%',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Avg Review Time',
                  value: '${campaign.averageReviewTimeMinutes} min',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricItem(
                  label: 'Pending Reviews',
                  value: campaign.pendingReviews.toString(),
                  color: Colors.orange,
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

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
