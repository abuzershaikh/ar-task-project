import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/worker_model.dart';

class KycTab extends StatelessWidget {
  final WorkerModel worker;

  const KycTab({
    super.key,
    required this.worker,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = worker.kycStatus == 'VERIFIED' || worker.kycStatus == 'APPROVED';
    final statusColor = isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final bgColor = isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Status Card
          Container(
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.verified_rounded : Icons.pending_actions_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KYC Verification Status',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isVerified ? 'VERIFIED & APPROVED' : 'PENDING REVIEW',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // KYC Details Card
          Container(
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
                      Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0284C7)),
                      SizedBox(width: 8),
                      Text(
                        'Worker Official Profile Info',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow('Full Legal Name', worker.name),
                  _buildInfoRow('Email Address', worker.email),
                  _buildInfoRow('Phone Contact', worker.phone.isNotEmpty ? worker.phone : 'Not Provided'),
                  _buildInfoRow('Account ID', worker.id),
                  _buildInfoRow('User UID', worker.userId.isNotEmpty ? worker.userId : worker.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

