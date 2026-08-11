import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WorkerCard extends StatelessWidget {
  final String workerId;
  final String name;
  final String phone;
  final double rating;
  final double score;
  final int totalTasks;
  final bool kycVerified;
  final String status;
  final double totalEarned;
  final double availableBalance;
  final VoidCallback onTap;

  const WorkerCard({
    super.key,
    required this.workerId,
    required this.name,
    required this.phone,
    required this.rating,
    required this.score,
    required this.totalTasks,
    required this.kycVerified,
    required this.status,
    required this.totalEarned,
    required this.availableBalance,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'INACTIVE':
        return AppColors.gray500;
      case 'SUSPENDED':
        return AppColors.warning;
      case 'BANNED':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header Row
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    workerId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    Icons.star,
                    rating.toStringAsFixed(1),
                    AppColors.warning,
                  ),
                  const SizedBox(width: 20),
                  _buildStatItem(
                    Icons.trending_up,
                    'Score ${score.toStringAsFixed(1)}',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 20),
                  _buildStatItem(
                    Icons.task_alt,
                    'Tasks $totalTasks',
                    AppColors.success,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // KYC & Status Row
              Row(
                children: [
                  if (kycVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'KYC ✓',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (kycVerified) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Earnings Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earned',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalEarned.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${availableBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
