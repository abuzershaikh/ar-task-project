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
    final int totalOrdersCount = orders.isNotEmpty ? orders.length : buyer.totalOrders;
    final int activeCount = orders.isNotEmpty
        ? orders.where((o) => (o['status'] ?? '').toString().toUpperCase() == 'ACTIVE').length
        : buyer.activeCampaigns;
    final int completedCount = orders.isNotEmpty
        ? orders.where((o) => (o['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length
        : 0;

    final double avgOrderValue = totalOrdersCount > 0 ? (buyer.totalSpend / totalOrdersCount) : 0.0;
    
    int totalTasksCommissioned = 0;
    int totalTasksCompleted = 0;
    for (final o in orders) {
      totalTasksCommissioned += ((o['totalTasksRequired'] ?? o['tasksRequired'] ?? 0) as num).toInt();
      totalTasksCompleted += ((o['tasksCompleted'] ?? 0) as num).toInt();
    }
    final double completionRate = totalTasksCommissioned > 0
        ? (totalTasksCompleted / totalTasksCommissioned * 100).clamp(0.0, 100.0)
        : (completedCount > 0 ? 100.0 : 0.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commercial Summary Card
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
                  _buildMetricRow('Total Platform Spend', '₹${buyer.totalSpend.toStringAsFixed(2)}', const Color(0xFF4F46E5)),
                  const SizedBox(height: 8),
                  _buildMetricRow('Average Order Value (AOV)', '₹${avgOrderValue.toStringAsFixed(2)}', const Color(0xFF0D9488)),
                  const SizedBox(height: 8),
                  _buildMetricRow('Total Campaigns Commissioned', '$totalOrdersCount Orders', const Color(0xFF1E1B4B)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Operational Performance Card
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
                      Icon(Icons.pie_chart_rounded, size: 18, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text(
                        'Campaign Delivery & Fulfillment',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildMetricRow('Active Running Campaigns', '$activeCount Active', const Color(0xFF16A34A)),
                  const SizedBox(height: 8),
                  _buildMetricRow('Completed Campaigns', '$completedCount Completed', const Color(0xFF0284C7)),
                  const SizedBox(height: 8),
                  if (totalTasksCommissioned > 0) ...[
                    _buildMetricRow('Tasks Commissioned', '$totalTasksCommissioned Units', const Color(0xFF64748B)),
                    const SizedBox(height: 8),
                    _buildMetricRow('Tasks Completed', '$totalTasksCompleted Units', const Color(0xFF16A34A)),
                    const SizedBox(height: 8),
                    _buildMetricRow('Fulfillment Completion Rate', '${completionRate.toStringAsFixed(1)}%', const Color(0xFF4F46E5)),
                  ] else ...[
                    _buildMetricRow('Fulfillment Status', totalOrdersCount > 0 ? 'Orders Processed' : 'Awaiting First Order', const Color(0xFF64748B)),
                  ],
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

