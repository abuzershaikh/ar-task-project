import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampaignCard extends StatelessWidget {
  final String orderId;
  final String title;
  final String buyerName;
  final String buyerEmail;
  final String taskType;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final double buyerUnitPrice;
  final double platformMargin;
  final double workerReward;
  final String status;
  final DateTime expiryDate;
  final VoidCallback onTap;

  const CampaignCard({
    super.key,
    required this.orderId,
    required this.title,
    required this.buyerName,
    this.buyerEmail = '',
    required this.taskType,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.buyerUnitPrice,
    required this.platformMargin,
    required this.workerReward,
    required this.status,
    required this.expiryDate,
    required this.onTap,
  });

  String _formatOrderId(String id) {
    if (id.length <= 10) return id;
    return '#${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $text'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF064E3B),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'PAUSED':
        return const Color(0xFFD97706);
      case 'COMPLETED':
        return const Color(0xFF0284C7);
      case 'PAYMENT_PENDING':
      case 'PENDING':
        return const Color(0xFFEA580C);
      case 'CANCELLED':
      case 'REJECTED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _getStatusBg() {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFFDCFCE7);
      case 'PAUSED':
        return const Color(0xFFFEF3C7);
      case 'COMPLETED':
        return const Color(0xFFE0F2FE);
      case 'PAYMENT_PENDING':
      case 'PENDING':
        return const Color(0xFFFFEDD5);
      case 'CANCELLED':
      case 'REJECTED':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C059669),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID Snippet with Copy Button & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _copyToClipboard(context, orderId, 'Campaign ID'),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.campaign_rounded, size: 14, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(
                              _formatOrderId(orderId),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF059669)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: _getStatusBg(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF064E3B),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Buyer & Task Type Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded, size: 13, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              buyerName,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (buyerEmail.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '($buyerEmail)',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined, size: 13, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            taskType,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedTasks / $totalTasks Tasks Completed',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(clampedProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: clampedProgress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Pricing Breakdown Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceItem('Buyer Price', '₹${buyerUnitPrice.toStringAsFixed(2)}', const Color(0xFF1E293B)),
                      _buildPriceItem('Worker Pay', '₹${workerReward.toStringAsFixed(2)}', const Color(0xFF059669)),
                      _buildPriceItem('Margin', '₹${platformMargin.toStringAsFixed(2)}', const Color(0xFF16A34A)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Footer Row: Expiry & Detail Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: daysRemaining < 2 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysRemaining < 0
                              ? 'Expired'
                              : daysRemaining == 0
                                  ? 'Expires today'
                                  : 'Expires in $daysRemaining days',
                          style: TextStyle(
                            fontSize: 11,
                            color: daysRemaining < 2 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF059669)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}


