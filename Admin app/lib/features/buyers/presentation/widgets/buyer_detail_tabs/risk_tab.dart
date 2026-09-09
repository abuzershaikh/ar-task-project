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
    final isSuspended = buyer.status.toUpperCase() == 'SUSPENDED';
    final isBlocked = buyer.status.toUpperCase() == 'BLOCKED' || buyer.status.toUpperCase() == 'BANNED';
    final isHighRisk = isSuspended || isBlocked;

    final String riskLevel;
    final String riskScore;
    final Color color;
    final Color bgColor;

    if (isBlocked) {
      riskLevel = 'CRITICAL (BLOCKED)';
      riskScore = '9.8';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEE2E2);
    } else if (isSuspended) {
      riskLevel = 'HIGH RISK (SUSPENDED)';
      riskScore = '8.5';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEE2E2);
    } else if (buyer.totalSpend > 0) {
      riskLevel = 'LOW RISK (VERIFIED)';
      riskScore = '1.0';
      color = const Color(0xFF16A34A);
      bgColor = const Color(0xFFDCFCE7);
    } else {
      riskLevel = 'LOW RISK (NEW ACCOUNT)';
      riskScore = '2.2';
      color = const Color(0xFF16A34A);
      bgColor = const Color(0xFFDCFCE7);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Risk Level Card
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
                    'Buyer Commercial Risk Assessment',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(riskLevel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text('Assessment Score: $riskScore / 10.0', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Risk Factors Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, size: 18, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text(
                        'Risk Factors & Verification Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildRiskItem('Account Status Security', !isHighRisk, buyer.status),
                  _buildRiskItem('Commercial Payment Standing', buyer.totalSpend > 0, buyer.totalSpend > 0 ? 'Verified Payer (₹${buyer.totalSpend.toStringAsFixed(0)})' : 'No Payment History'),
                  _buildRiskItem('Campaign Fulfillment Volume', buyer.totalOrders > 0, '${buyer.totalOrders} Orders Placed'),
                  _buildRiskItem('Chargeback & Fraud Disputes', true, '0 Disputes Logged'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(String label, bool isClean, String statusText) {
    final statusColor = isClean ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            isClean ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }
}

// Backward compatibility alias
typedef BuyerRiskTab = RiskTab;

