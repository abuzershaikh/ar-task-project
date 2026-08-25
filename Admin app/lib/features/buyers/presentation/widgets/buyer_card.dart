import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BuyerCard extends StatelessWidget {
  final String buyerId;
  final String companyName;
  final String email;
  final int totalOrders;
  final int activeCampaigns;
  final double totalSpend;
  final String status;
  final VoidCallback onTap;

  const BuyerCard({
    super.key,
    required this.buyerId,
    required this.companyName,
    required this.email,
    required this.totalOrders,
    required this.activeCampaigns,
    required this.totalSpend,
    required this.status,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'SUSPENDED':
        return const Color(0xFFD97706);
      case 'BLOCKED':
      case 'BANNED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _formatBuyerId(String id) {
    if (id.length <= 12) return id;
    return '#${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A4F46E5),
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
              // ── Header: Avatar + Company/Email + Status Pill ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'B',
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
                          companyName.isNotEmpty ? companyName : 'Buyer Account',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isNotEmpty ? email : _formatBuyerId(buyerId),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4F46E5),
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

              // ── Stat Badges Wrap Row ───
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildPill(
                    icon: Icons.shopping_bag_rounded,
                    label: '$totalOrders Orders',
                    bgColor: const Color(0xFFEDE9FE),
                    textColor: const Color(0xFF4F46E5),
                    iconColor: const Color(0xFF4F46E5),
                  ),
                  _buildPill(
                    icon: Icons.campaign_rounded,
                    label: '$activeCampaigns Active Campaigns',
                    bgColor: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF16A34A),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  _buildPill(
                    icon: Icons.fingerprint_rounded,
                    label: _formatBuyerId(buyerId),
                    bgColor: const Color(0xFFF1F5F9),
                    textColor: const Color(0xFF64748B),
                    iconColor: const Color(0xFF64748B),
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
                        'Total Spend Volume',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatCurrency(totalSpend),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 10),
                    label: const Text(
                      'Buyer Profile',
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
