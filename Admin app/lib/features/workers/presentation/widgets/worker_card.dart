import 'package:flutter/material.dart';
import '../../../../core/widgets/app_avatar.dart';

class WorkerCard extends StatelessWidget {
  final String workerId;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final double rating;
  final double score;
  final int totalTasks;
  final bool kycVerified;
  final String status;
  final double totalEarned;
  final double availableBalance;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;
  final VoidCallback? onDelete;

  const WorkerCard({
    super.key,
    required this.workerId,
    required this.name,
    this.email = '',
    required this.phone,
    this.avatarUrl,
    required this.rating,
    required this.score,
    required this.totalTasks,
    required this.kycVerified,
    required this.status,
    required this.totalEarned,
    required this.availableBalance,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
    this.onDelete,
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
        color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? const Color(0x1F0284C7) : const Color(0x0C0284C7),
            blurRadius: isSelected ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: isSelectionMode ? () => onSelectChanged?.call(!isSelected) : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Checkbox + Avatar + Name/Phone + Status Pill ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isSelectionMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: onSelectChanged,
                          activeColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                    ),
                  ],
                  AppAvatar(
                    name: name,
                    imageUrl: avatarUrl,
                    radius: 19,
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
                  if (onDelete != null && !isSelectionMode) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
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


