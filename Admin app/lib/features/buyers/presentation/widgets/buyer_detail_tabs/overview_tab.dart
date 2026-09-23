import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../data/models/buyer_model.dart';

class OverviewTab extends StatelessWidget {
  final BuyerModel buyer;
  final List<dynamic> orders;
  final List<dynamic> payments;

  const OverviewTab({
    super.key,
    required this.buyer,
    this.orders = const [],
    this.payments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Buyer Profile Hero Card ───────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: buyer.name,
                  imageUrl: buyer.avatarUrl,
                  userId: buyer.id,
                  radius: 30,
                  border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        buyer.email.isNotEmpty ? buyer.email : buyer.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: buyer.status == 'ACTIVE' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          buyer.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: buyer.status == 'ACTIVE' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Company Details Card
          _buildCard(
            'Company & Identity Details',
            Icons.business_rounded,
            [
              _buildRow('Business / Client Name', buyer.name, const Color(0xFF1E1B4B)),
              _buildRow('Email Address', buyer.email, const Color(0xFF1E1B4B)),
              _buildRow('Phone Number', buyer.phone.isNotEmpty ? buyer.phone : 'Not Provided', const Color(0xFF64748B)),
              _buildRow('Account Status', buyer.status, buyer.status == 'ACTIVE' ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
              _buildRow('Buyer UID', buyer.id, const Color(0xFF4F46E5)),
            ],
          ),

          const SizedBox(height: 12),

          // Order Summary Card
          _buildCard(
            'Order Operations Summary',
            Icons.shopping_bag_rounded,
            [
              _buildStatRow('Total Orders Placed', '${orders.isNotEmpty ? orders.length : buyer.totalOrders}', const Color(0xFF4F46E5), const Color(0xFFEDE9FE)),
              _buildStatRow('Active Running Campaigns', '${buyer.activeCampaigns}', const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
            ],
          ),

          const SizedBox(height: 12),

          // Financial Summary Card
          _buildCard(
            'Financial Commercial Volume',
            Icons.account_balance_wallet_rounded,
            [
              _buildStatRow('Total Platform Spend', '₹${buyer.totalSpend.toStringAsFixed(2)}', const Color(0xFF4F46E5), const Color(0xFFEDE9FE)),
              _buildStatRow('Payment Transactions', '${payments.length}', const Color(0xFF0D9488), const Color(0xFFCCFBF1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
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
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3), width: 0.8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Alias for backward compatibility
typedef BuyerOverviewTab = OverviewTab;

