import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerReviewsTab extends StatelessWidget {
  final String buyerId;

  const BuyerReviewsTab({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Pending', '23', AppColors.warning),
                  _buildStatRow('Approved', '1,150', AppColors.success),
                  _buildStatRow('Rejected', '45', AppColors.error),
                  _buildStatRow('Request Changes', '12', AppColors.info),
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
