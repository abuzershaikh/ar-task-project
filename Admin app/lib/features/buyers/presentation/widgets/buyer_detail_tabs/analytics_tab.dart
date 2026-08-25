import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class AnalyticsTab extends StatelessWidget {
  final BuyerModel buyer;
  final List<dynamic> orders;

  const AnalyticsTab({
    super.key,
    required this.buyer,
    this.orders = const [],
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOrders = orders.isNotEmpty ? orders.length : buyer.totalOrders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_rounded, size: 18, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text(
                        'Commercial Volume Analytics',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildMetricRow('Total Orders Placed', '$effectiveOrders Orders', const Color(0xFF4F46E5)),
                  const SizedBox(height: 8),
                  _buildMetricRow('Active Running Campaigns', '${buyer.activeCampaigns}', const Color(0xFF16A34A)),
                  const SizedBox(height: 8),
                  _buildMetricRow('Total Platform Spend', '₹${buyer.totalSpend.toStringAsFixed(2)}', const Color(0xFF1E1B4B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Backward compatibility alias
typedef BuyerAnalyticsTab = AnalyticsTab;

