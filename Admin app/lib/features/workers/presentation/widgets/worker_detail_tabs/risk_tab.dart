import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class RiskTab extends StatelessWidget {
  final String workerId;

  const RiskTab({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
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
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: AppColors.success,
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
                  const Text(
                    'LOW',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Risk Score: 18 / 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Fraud Signal Checklist
          const Text(
            'Fraud Detection Signals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSignalItem(
                    true,
                    'Normal completion speed',
                    'Tasks completed at consistent pace',
                  ),
                  _buildSignalItem(
                    true,
                    'Stable device fingerprint',
                    'Same device used consistently',
                  ),
                  _buildSignalItem(
                    true,
                    'Good rating history',
                    'Positive feedback from buyers',
                  ),
                  _buildSignalItem(
                    true,
                    'No suspicious IP switching',
                    'Consistent location patterns',
                  ),
                  _buildSignalItem(
                    true,
                    'Valid proof submissions',
                    'Authentic screenshots and proofs',
                  ),
                  _buildSignalItem(
                    true,
                    'No duplicate accounts detected',
                    'Unique identity verified',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Incident Statistics
          const Text(
            'Incident Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildIncidentCard('Failed Tasks', '12', AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncidentCard('Timeouts', '3', AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIncidentCard('Duplicate Attempts', '0', AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIncidentCard('Warnings', '0', AppColors.success),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Risk Actions
          const Text(
            'Risk Management Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.pause_circle, size: 18),
            label: const Text('Suspend Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Ban Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Clear Warning'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalItem(bool isGood, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.cancel,
            color: isGood ? AppColors.success : AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
