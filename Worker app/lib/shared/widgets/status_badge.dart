import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable status badge chip.
/// Renders a coloured pill with the task status text.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  Color _colorForStatus(String s) {
    switch (s.toUpperCase()) {
      case 'APPROVED':
      case 'COMPLETED':
        return AppTheme.accentColor;
      case 'REJECTED':
      case 'FAILED':
      case 'EXPIRED':
        return AppTheme.dangerColor;
      case 'IN_PROGRESS':
      case 'ACCEPTED':
      case 'ASSIGNED':
        return AppTheme.primaryColor;
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
      case 'UNDER-REVIEW':
        return AppTheme.warningColor;
      default:
        return AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('-', ' '),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
