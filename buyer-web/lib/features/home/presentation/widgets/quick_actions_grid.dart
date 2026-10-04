import 'package:flutter/material.dart';

class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onCreateCampaign;
  final VoidCallback onServices;
  final VoidCallback onReviews;
  final VoidCallback onPayments;
  final VoidCallback onAnalytics;
  final VoidCallback onInvoices;

  const QuickActionsGrid({
    super.key,
    required this.onCreateCampaign,
    required this.onServices,
    required this.onReviews,
    required this.onPayments,
    required this.onAnalytics,
    required this.onInvoices,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.add_circle_rounded,
            label: 'Create Campaign',
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            onTap: onCreateCampaign,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.grid_view_rounded,
            label: 'Services Catalog',
            color: const Color(0xFF9333EA),
            bgColor: const Color(0xFFF3E8FF),
            onTap: onServices,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.fact_check_rounded,
            label: 'Task Reviews',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            onTap: onReviews,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.trending_up_rounded,
            label: 'Performance',
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFF0FDF4),
            onTap: onAnalytics,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Payments',
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            onTap: onPayments,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Invoices',
            color: const Color(0xFF4F46E5),
            bgColor: const Color(0xFFEEF2FF),
            onTap: onInvoices,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 175,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
