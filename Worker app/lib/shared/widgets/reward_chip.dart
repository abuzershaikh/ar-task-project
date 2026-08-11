import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable reward chip widget.
/// Displays a small gradient pill with ₹ amount.
class RewardChip extends StatelessWidget {
  final dynamic reward;
  final double fontSize;

  const RewardChip({
    super.key,
    required this.reward,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.rewardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.currency_rupee, size: fontSize - 1, color: Colors.white),
          Text(
            '$reward',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
