import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerAnalyticsTab extends StatelessWidget {
  final String buyerId;

  const BuyerAnalyticsTab({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricCard('Total Orders', '124', Icons.shopping_bag),
          _buildMetricCard('Completion Rate', '94%', Icons.check_circle),
          _buildMetricCard('Avg Campaign Budget', '500 tasks', Icons.trending_up),
          _buildMetricCard('Total Spend', '₹2.4L', Icons.currency_rupee),
          _buildMetricCard('Rejection Rate', '4.2%', Icons.cancel),
          _buildMetricCard('Avg Review Time', '2h 12m', Icons.timer),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.gray600)),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
