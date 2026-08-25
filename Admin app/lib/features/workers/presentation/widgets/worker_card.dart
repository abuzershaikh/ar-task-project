import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WorkerCard extends StatelessWidget {
  final String workerId;
  final String name;
  final String email;
  final String phone;
  final double rating;
  final double score;
  final int totalTasks;
  final bool kycVerified;
  final String status;
  final double totalEarned;
  final double availableBalance;
  final VoidCallback onTap;

  const WorkerCard({
    super.key,
    required this.workerId,
    required this.name,
    this.email = '',
    required this.phone,
    required this.rating,
    required this.score,
    required this.totalTasks,
    required this.kycVerified,
    required this.status,
    required this.totalEarned,
    required this.availableBalance,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'INACTIVE':
        return const Color(0xFF64748B);
      case 'SUSPENDED':
        return const Color(0xFFD97706);
      case 'BANNED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _formatWorkerId(String id) {
    if (id.length <= 12) return id;
    return '#${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0284C7),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar + Name/Phone + Status Pill ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Worker Account',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isNotEmpty ? email : (phone.isNotEmpty ? phone : _formatWorkerId(workerId)),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4), width: 0.8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Badge Wrap Row (Never Overflows) ───
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildPill(
                    icon: Icons.star_rounded,
                    label: rating.toStringAsFixed(1),
                    bgColor: const Color(0xFFFEF3C7),
                    textColor: const Color(0xFFD97706),
                    iconColor: const Color(0xFFD97706),
                  ),
                  _buildPill(
                    icon: Icons.task_alt_rounded,
                    label: '$totalTasks Tasks',
                    bgColor: const Color(0xFFE0F2FE),
                    textColor: const Color(0xFF0284C7),
                    iconColor: const Color(0xFF0284C7),
                  ),
                  _buildPill(
                    icon: Icons.speed_rounded,
                    label: 'Score ${score.toStringAsFixed(0)}',
                    bgColor: const Color(0xFFCCFBF1),
                    textColor: const Color(0xFF0D9488),
                    iconColor: const Color(0xFF0D9488),
                  ),
                  if (kycVerified)
                    _buildPill(
                      icon: Icons.verified_rounded,
                      label: 'KYC Verified',
                      bgColor: const Color(0xFFDCFCE7),
                      textColor: const Color(0xFF16A34A),
                      iconColor: const Color(0xFF16A34A),
                    )
                  else
                    _buildPill(
                      icon: Icons.pending_rounded,
                      label: 'KYC Pending',
                      bgColor: const Color(0xFFFFEDD5),
                      textColor: const Color(0xFFEA580C),
                      iconColor: const Color(0xFFEA580C),
                    ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 10),

              // ── Financial Summary & Action Footer ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earned',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '₹${totalEarned.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '₹${availableBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 10),
                    label: const Text(
                      'Profile',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


