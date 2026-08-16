import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class BuyerRiskTab extends StatelessWidget {
  final BuyerModel buyer;

  const BuyerRiskTab({
    super.key,
    required this.buyer,
  });

  @override
  Widget build(BuildContext context) {
    final isHighRisk = buyer.status == 'SUSPENDED' || buyer.status == 'BANNED' || buyer.status == 'BLOCKED';
    final riskLevel = isHighRisk ? 'HIGH' : 'LOW';
    final color = isHighRisk ? AppColors.error : AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.shield, color: color, size: 48),
                  const SizedBox(height: 16),
                  Text('Risk Level: $riskLevel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 8),
                  Text('Status: ${buyer.status}', style: const TextStyle(color: AppColors.gray600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Total Orders', '${buyer.totalOrders}', AppColors.primary),
                  _buildStatRow('Active Campaigns', '${buyer.activeCampaigns}', AppColors.success),
                  _buildStatRow('Total Spend', '₹${buyer.totalSpend.toStringAsFixed(2)}', AppColors.info),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
