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
    final riskLevel = (risk['riskLevel'] ?? (worker.status == 'BANNED' ? 'HIGH' : 'LOW')).toString();
    final riskScore = risk['riskScore'] != null ? risk['riskScore'].toString() : '1.2';

    final Color color = riskLevel == 'HIGH' ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final Color bgColor = riskLevel == 'HIGH' ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);

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
                      fontSize: 28,
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
        ],
      ),
    );
  }
}

