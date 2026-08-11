import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ActionBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const ActionBanner({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color, size: 14),
        ],
      ),
    );
  }
}
