import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class OrdersTab extends StatelessWidget {
  final BuyerModel? buyer;
  final List<dynamic> orders;

  const OrdersTab({
    super.key,
    this.buyer,
    this.orders = const [],
  });

  String _formatOrderId(String id) {
    if (id.length <= 12) return id;
    return '#${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'No orders or campaigns created yet',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final item = orders[index];
        final rawId = (item['id'] ?? 'ORD-${index + 1}').toString();
        final title = (item['title'] ?? item['name'] ?? 'Campaign #${index + 1}').toString();
        final status = (item['status'] ?? 'ACTIVE').toString().toUpperCase();
        final budget = item['totalAmount'] != null ? '₹${item['totalAmount']}' : (item['budget'] != null ? '₹${item['budget']}' : '₹0.00');
        final tasksRequired = item['totalTasksRequired'] ?? item['tasksRequired'] ?? 0;
        final rewardPerTask = item['rewardPerTask'] != null ? '₹${item['rewardPerTask']}' : null;

        Color statusColor = const Color(0xFF16A34A);
        Color bgColor = const Color(0xFFDCFCE7);
        if (status.contains('CANCEL') || status.contains('REJECT')) {
          statusColor = const Color(0xFFDC2626);
          bgColor = const Color(0xFFFEE2E2);
        } else if (status.contains('PAUSE') || status.contains('PENDING')) {
          statusColor = const Color(0xFFD97706);
          bgColor = const Color(0xFFFEF3C7);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x084F46E5),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatOrderId(rawId),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                        Text(budget, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                      ],
                    ),
                    if (tasksRequired > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tasks Required', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                          Text('$tasksRequired Tasks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                        ],
                      ),
                    if (rewardPerTask != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Per Task', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                          Text(rewardPerTask, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
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

// Backward compatibility alias
typedef BuyerOrdersTab = OrdersTab;

