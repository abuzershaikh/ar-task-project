import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashboardStatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool isWhite;

  const DashboardStatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isWhite ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isWhite ? Colors.white.withOpacity(0.9) : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: textColor,
          size: 24,
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.statNumber.copyWith(
            color: textColor,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.arrow_upward,
              size: 12,
              color: secondaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              trend,
              style: AppTextStyles.caption.copyWith(
                color: secondaryColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
