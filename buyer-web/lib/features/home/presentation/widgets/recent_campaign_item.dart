import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../domain/entities/campaign_summary.dart';

class RecentCampaignItem extends StatelessWidget {
  final CampaignSummary campaign;

  const RecentCampaignItem({
    super.key,
    required this.campaign,
  });

  @override
  Widget build(BuildContext context) {
    final progress = campaign.totalTasks > 0
        ? campaign.completedTasks / campaign.totalTasks
        : 0.0;
    final progressPercent = (progress * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.campaignDetail,
          arguments: campaign.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getStatusColor(campaign.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getServiceIcon(campaign.serviceType),
                color: _getStatusColor(campaign.status),
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Campaign Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          campaign.name,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(campaign.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          campaign.status.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(
                            color: _getStatusColor(campaign.status),
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'ID: ${campaign.id}',
                    style: AppTextStyles.caption,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(campaign.status),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$progressPercent%',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: _getStatusColor(campaign.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        '${campaign.completedTasks} / ${campaign.totalTasks} completed',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      if (campaign.expiresIn != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              campaign.expiresIn!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Flexible(
                        child: _buildStatusChip(
                          '${campaign.pendingTasks} Pending',
                          AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _buildStatusChip(
                          '${campaign.inProgressTasks} In Progress',
                          AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            const Icon(
              Icons.more_vert,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.activeStatus;
      case 'completed':
        return AppColors.completedStatus;
      case 'in_progress':
      case 'in progress':
        return AppColors.inProgressStatus;
      case 'paused':
        return AppColors.pausedStatus;
      case 'cancelled':
        return AppColors.cancelledStatus;
      default:
        return AppColors.pendingStatus;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'product_testing':
        return Icons.shopping_bag_outlined;
      case 'survey':
        return Icons.quiz_outlined;
      case 'feedback':
        return Icons.rate_review_outlined;
      case 'store_visit':
        return Icons.store_outlined;
      case 'hotel_audit':
        return Icons.hotel_outlined;
      default:
        return Icons.task_outlined;
    }
  }
}
