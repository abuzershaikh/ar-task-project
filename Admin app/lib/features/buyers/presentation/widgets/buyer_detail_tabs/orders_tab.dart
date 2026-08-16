import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class BuyerOrdersTab extends StatelessWidget {
  final BuyerModel buyer;
  final List<dynamic> orders;

  const BuyerOrdersTab({
    super.key,
    required this.buyer,
    this.orders = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_outlined, size: 48, color: AppColors.gray400),
            const SizedBox(height: 12),
            Text(
              'No orders recorded for ${buyer.name}',
              style: const TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final item = orders[index];
        final orderId = (item['id'] ?? 'ORD-${index + 1}').toString();
        final title = (item['title'] ?? item['name'] ?? 'Campaign #${index + 1}').toString();
        final status = (item['status'] ?? 'ACTIVE').toString().toUpperCase();
        final budget = item['budget'] != null ? '₹${item['budget']}' : '₹0.00';

        Color statusColor = AppColors.success;
        if (status.contains('CANCEL') || status.contains('PAUSE')) statusColor = AppColors.warning;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget: $budget', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
