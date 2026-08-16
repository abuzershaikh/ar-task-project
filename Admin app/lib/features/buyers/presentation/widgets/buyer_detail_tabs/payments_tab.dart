import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class BuyerPaymentsTab extends StatelessWidget {
  final BuyerModel buyer;
  final List<dynamic> payments;

  const BuyerPaymentsTab({
    super.key,
    required this.buyer,
    this.payments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFinanceRow('Total Spend', '₹${buyer.totalSpend.toStringAsFixed(2)}', AppColors.primary),
                  _buildFinanceRow('Total Orders', '${buyer.totalOrders}', AppColors.info),
                  _buildFinanceRow('Active Campaigns', '${buyer.activeCampaigns}', AppColors.success),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Transaction History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          payments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No payment transactions recorded', style: TextStyle(color: AppColors.gray600)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final item = payments[index];
                    final amount = item['amount'] != null ? '₹${item['amount']}' : '₹0.00';
                    final payId = (item['id'] ?? 'PAY-${index + 1}').toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.payment, color: AppColors.success),
                        title: Text(payId),
                        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
