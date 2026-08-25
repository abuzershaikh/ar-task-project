import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class RiskTab extends StatelessWidget {
  final BuyerModel buyer;
  final Map<String, dynamic> risk;

  const RiskTab({
    super.key,
    required this.buyer,
    this.risk = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isHighRisk = buyer.status == 'SUSPENDED' || buyer.status == 'BANNED' || buyer.status == 'BLOCKED';
    final riskLevel = (risk['riskLevel'] ?? (isHighRisk ? 'HIGH' : 'LOW')).toString();
    final color = riskLevel == 'HIGH' ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final bgColor = riskLevel == 'HIGH' ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_rounded, color: color, size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Buyer Risk Assessment',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text('Risk Level: $riskLevel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text('Account Status: ${buyer.status}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                  _buildStatRow('Total Orders Placed', '${buyer.totalOrders}', const Color(0xFF4F46E5)),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  _buildStatRow('Active Campaigns', '${buyer.activeCampaigns}', const Color(0xFF16A34A)),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  _buildStatRow('Total Spend Volume', '₹${buyer.totalSpend.toStringAsFixed(2)}', const Color(0xFF1E1B4B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
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
typedef BuyerRiskTab = RiskTab;

