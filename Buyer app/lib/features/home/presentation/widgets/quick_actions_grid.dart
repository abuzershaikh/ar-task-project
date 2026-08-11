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
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Create',
            color: Colors.blue,
            onTap: onCreateCampaign,
          ),
          _QuickActionButton(
            icon: Icons.shopping_bag_outlined,
            label: 'Services',
            color: Colors.purple,
            onTap: onServices,
          ),
          _QuickActionButton(
            icon: Icons.check_circle_outline,
            label: 'Reviews',
            color: Colors.green,
            onTap: onReviews,
          ),
          _QuickActionButton(
            icon: Icons.payment,
            label: 'Payments',
            color: Colors.orange,
            onTap: onPayments,
          ),
          _QuickActionButton(
            icon: Icons.bar_chart,
            label: 'Analytics',
            color: Colors.teal,
            onTap: onAnalytics,
          ),
          _QuickActionButton(
            icon: Icons.receipt_long,
            label: 'Invoices',
            color: Colors.indigo,
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
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
