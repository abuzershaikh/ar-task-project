import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CampaignCard extends StatelessWidget {
  final String orderId;
  final String title;
  final String buyerName;
  final String taskType;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final double buyerUnitPrice;
  final double platformMargin;
  final double workerReward;
  final String status;
  final DateTime expiryDate;
  final VoidCallback onTap;

  const CampaignCard({
    super.key,
    required this.orderId,
    required this.title,
    required this.buyerName,
    required this.taskType,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.buyerUnitPrice,
    required this.platformMargin,
    required this.workerReward,
    required this.status,
    required this.expiryDate,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PAUSED':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.info;
      case 'PAYMENT_PENDING':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'PAUSED':
        return 'Paused';
      case 'COMPLETED':
        return 'Completed';
      case 'PAYMENT_PENDING':
        return 'Payment Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderId,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor()),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Buyer & Task Type
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(
                    buyerName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      taskType,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedTasks / $totalTasks tasks',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.gray200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pricing Breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceItem('Buyer Price', '₹${buyerUnitPrice.toStringAsFixed(2)}', AppColors.gray700),
                    _buildPriceItem('Margin', '₹${platformMargin.toStringAsFixed(2)}', AppColors.success),
                    _buildPriceItem('Worker', '₹${workerReward.toStringAsFixed(2)}', AppColors.primary),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Expiry
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: daysRemaining < 2 ? AppColors.error : AppColors.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysRemaining < 0
                        ? 'Expired'
                        : daysRemaining == 0
                            ? 'Expires today'
                            : 'Expires in $daysRemaining days',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysRemaining < 2 ? AppColors.error : AppColors.gray600,
                      fontWeight: daysRemaining < 2 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
