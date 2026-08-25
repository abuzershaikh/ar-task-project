import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class PaymentsTab extends StatelessWidget {
  final BuyerModel? buyer;
  final List<dynamic> payments;

  const PaymentsTab({
    super.key,
    this.buyer,
    this.payments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (buyer != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x084F46E5),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildFinanceRow('Total Spend Volume', '₹${buyer!.totalSpend.toStringAsFixed(2)}', const Color(0xFF4F46E5)),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildFinanceRow('Total Campaigns Ordered', '${buyer!.totalOrders}', const Color(0xFF1E1B4B)),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildFinanceRow('Active Live Campaigns', '${buyer!.activeCampaigns}', const Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Financial Transactions Ledger',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          payments.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.payment_outlined, size: 40, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 8),
                      Text(
                        'No direct deposit or credit logs recorded',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ],
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
                    final type = item['type'] ?? 'Top-up Deposit';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                        ),
                        title: Text(type.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E1B4B))),
                        subtitle: Text(payId, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        trailing: Text(
                          amount,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A)),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Backward compatibility alias
typedef BuyerPaymentsTab = PaymentsTab;

