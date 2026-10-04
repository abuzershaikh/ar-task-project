import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: (isSmall ? AppTextStyles.overline : AppTextStyles.labelSmall).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 9 : 11,
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
      case 'pending':
        return AppColors.pendingStatus;
      case 'paused':
        return AppColors.pausedStatus;
      case 'cancelled':
      case 'rejected':
        return AppColors.cancelledStatus;
      case 'expired':
        return AppColors.expiredStatus;
      case 'approved':
        return AppColors.success;
      case 'under_review':
      case 'under review':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
