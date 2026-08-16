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
    final riskScore = risk['riskScore'] != null ? risk['riskScore'].toString() : '1.0';

    final Color color = riskLevel == 'HIGH' ? AppColors.error : AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk Level Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield,
                      color: color,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Risk Level',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    riskLevel,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assessment Score: $riskScore / 10.0',
                    style: const TextStyle(fontSize: 13, color: AppColors.gray600),
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
