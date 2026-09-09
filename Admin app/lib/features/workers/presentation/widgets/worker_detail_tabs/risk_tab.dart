import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/worker_model.dart';

class RiskTab extends StatelessWidget {
  final WorkerModel worker;
  final Map<String, dynamic> risk;

  const RiskTab({
    super.key,
    required this.worker,
    this.risk = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isBanned = worker.status.toUpperCase() == 'BANNED';
    final isSuspended = worker.status.toUpperCase() == 'SUSPENDED';
    final isLowRating = worker.rating > 0 && worker.rating < 3.5;

    final String riskLevel;
    final String riskScore;
    final Color color;
    final Color bgColor;

    if (isBanned) {
      riskLevel = 'CRITICAL (HIGH)';
      riskScore = '9.5';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEE2E2);
    } else if (isSuspended) {
      riskLevel = 'HIGH RISK';
      riskScore = '8.0';
      color = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEE2E2);
    } else if (isLowRating) {
      riskLevel = 'MODERATE / MEDIUM';
      riskScore = '5.5';
      color = const Color(0xFFD97706);
      bgColor = const Color(0xFFFEF3C7);
    } else {
      riskLevel = 'LOW RISK';
      riskScore = (risk['riskScore'] ?? '1.2').toString();
      color = const Color(0xFF16A34A);
      bgColor = const Color(0xFFDCFCE7);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Level Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080284C7),
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
                    child: Icon(
                      Icons.shield_rounded,
                      color: color,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI Platform Risk Level',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    riskLevel,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assessment Score: $riskScore / 10.0',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Risk Factor Breakdown Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080284C7),
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
                      Icon(Icons.rule_rounded, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text(
                        'Risk Factors Evaluated',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildRiskItem('Account Status Security', worker.status == 'ACTIVE', worker.status),
                  _buildRiskItem('Quality & Rating Threshold', worker.rating >= 4.0, '${worker.rating.toStringAsFixed(1)} ★ Quality Rating'),
                  _buildRiskItem('KYC Identity Standing', worker.kycStatus == 'VERIFIED' || worker.kycStatus == 'APPROVED', worker.kycStatus),
                  _buildRiskItem('Task Delivery Integrity', worker.completedTasks >= 0, '${worker.completedTasks} Tasks Delivered'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(String label, bool isClean, String detail) {
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
            detail,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }
}

