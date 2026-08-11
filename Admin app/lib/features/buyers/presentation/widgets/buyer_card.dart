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
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'SUSPENDED':
        return AppColors.warning;
      case 'BLOCKED':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    buyerId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  _buildStatItem('Orders', totalOrders.toString(), AppColors.primary),
                  const SizedBox(width: 20),
                  _buildStatItem('Active', activeCampaigns.toString(), AppColors.success),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Spend',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                  Text(
                    '₹${(totalSpend / 100000).toStringAsFixed(1)}L',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
