import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerPaymentsTab extends StatelessWidget {
  final String buyerId;

  const BuyerPaymentsTab({super.key, required this.buyerId});

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
                  _buildFinanceRow('Total Paid', '₹2,40,000', AppColors.primary),
                  _buildFinanceRow('Pending', '₹0', AppColors.warning),
                  _buildFinanceRow('Refunded', '₹5,000', AppColors.error),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.payment, color: AppColors.success),
                  title: Text('PAY-${1000 + index}'),
                  subtitle: Text('${index + 1} days ago'),
                  trailing: const Text('₹25,000', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
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
