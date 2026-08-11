import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerRiskTab extends StatelessWidget {
  final String buyerId;

  const BuyerRiskTab({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.shield, color: AppColors.success, size: 48),
                  const SizedBox(height: 16),
                  const Text('Risk Level: LOW', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success)),
                  const SizedBox(height: 8),
                  const Text('Risk Score: 12 / 100', style: TextStyle(color: AppColors.gray600)),
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
                  _buildStatRow('Payment Issues', '0', AppColors.success),
                  _buildStatRow('Cancelled Orders', '2', AppColors.warning),
                  _buildStatRow('Refund Rate', '1.2%', AppColors.info),
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
