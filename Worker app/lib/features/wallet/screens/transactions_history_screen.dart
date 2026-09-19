import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

/// Worker Transaction History Screen:
/// - Fetches unified transactions (Earnings, Withdrawals, Deductions)
/// - Supports filters: 'All', 'Withdrawals', 'Earnings'
/// - Human-readable date formatting (e.g. 16 Sep 2026, 03:20 PM)
/// - Accurate status badges (PAID, COMPLETED, PROCESSING, REJECTED)
/// - Pull-to-refresh enabled
class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final res = await ApiService.getEarnings();
      final list = (res['transactions'] ??
          res['earnings'] ??
          res['history'] ??
          res['data'] ??
          []) as List<dynamic>;
      if (mounted) {
        setState(() {
          _transactions = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final str = rawDate.toString().trim();
    if (str.isEmpty) return '';
    try {
      final dt = DateTime.parse(str).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, $hour:$minute $period';
    } catch (_) {
      return str;
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
      case 'POSTED':
        return const Color(0xFFE6F4EA);
      case 'PROCESSING':
      case 'UNDER_REVIEW':
      case 'REQUESTED':
      case 'PENDING':
        return const Color(0xFFFEF3C7);
      case 'REJECTED':
      case 'DECLINED':
      case 'FAILED':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE0F2FE);
    }
  }

  Color _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SUCCESS':
      case 'POSTED':
        return const Color(0xFF00875A);
      case 'PROCESSING':
      case 'UNDER_REVIEW':
      case 'REQUESTED':
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'REJECTED':
      case 'DECLINED':
      case 'FAILED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0284C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Exclude any non-worker buyer campaign orders
    final workerTransactions = _transactions.where((tx) {
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final desc = (tx['description'] ?? '').toString().toLowerCase();
      if (title.contains('campaign order') || desc.contains('campaign order')) {
        return false;
      }
      return true;
    }).toList();

    // 2. Filter strictly by selected tab
    final filteredList = workerTransactions.where((tx) {
      final type = (tx['type'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'Withdrawals') {
        return type == 'WITHDRAWAL' || type == 'PAYOUT';
      }
      if (_selectedFilter == 'Earnings') {
        return type == 'EARNING' ||
            type == 'REWARD' ||
            type == 'CREDIT' ||
            type == 'TASK_COMPLETION';
      }
      // 'All' tab shows both earnings and withdrawals
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['All', 'Withdrawals', 'Earnings'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),

            // Transactions List with RefreshIndicator
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : RefreshIndicator(
                      onRefresh: _fetchTransactions,
                      color: const Color(0xFF2563EB),
                      child: filteredList.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.45,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.history_toggle_off_rounded,
                                          size: 54,
                                          color: Colors.black26,
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'No transaction history found',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Your earnings and payout logs will appear here',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() => _isLoading = true);
                                            _fetchTransactions();
                                          },
                                          icon: const Icon(Icons.refresh_rounded,
                                              size: 16),
                                          label: const Text('Refresh'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final tx = filteredList[index];
                                final typeStr = (tx['type'] ?? '')
                                    .toString()
                                    .toUpperCase();
                                final isDeduction = typeStr == 'DEDUCTION';
                                final isWithdrawal = typeStr == 'WITHDRAWAL' ||
                                    typeStr == 'PAYOUT' ||
                                    isDeduction;

                                final title = (tx['title'] ??
                                        tx['description'] ??
                                        (isWithdrawal
                                            ? 'Payout Request'
                                            : 'Task Earnings'))
                                    .toString();

                                final subtitle = tx['description'] != null &&
                                        tx['description'].toString() != title
                                    ? tx['description'].toString()
                                    : null;

                                final dateStr =
                                    _formatDate(tx['date'] ?? tx['createdAt']);
                                final amount =
                                    (tx['amount'] ?? 0.0).toDouble();
                                final status =
                                    (tx['status'] ?? 'COMPLETED').toString();
                                final isRejected = status == 'REJECTED' ||
                                    status == 'DECLINED' ||
                                    status == 'FAILED';
                                final rejectionReason = (tx['rejectionReason'] ??
                                        tx['metadata']?['rejectionReason'])
                                    ?.toString();
                                final displayStatus = isRejected ? 'DECLINED' : status;

                                // Choose appropriate icon & icon background
                                IconData itemIcon;
                                Color iconColor;
                                Color iconBg;

                                if (isDeduction) {
                                  itemIcon = Icons.remove_circle_outline_rounded;
                                  iconColor = const Color(0xFFDC2626);
                                  iconBg = const Color(0xFFFEE2E2);
                                } else if (isWithdrawal) {
                                  if (isRejected) {
                                    itemIcon = Icons.cancel_rounded;
                                    iconColor = const Color(0xFFDC2626);
                                    iconBg = const Color(0xFFFEE2E2);
                                  } else {
                                    itemIcon = Icons.arrow_upward_rounded;
                                    iconColor = const Color(0xFF0284C7);
                                    iconBg = const Color(0xFFE0F2FE);
                                  }
                                } else {
                                  itemIcon = Icons.arrow_downward_rounded;
                                  iconColor = const Color(0xFF00875A);
                                  iconBg = const Color(0xFFE6F4EA);
                                }

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showTransactionDetails(
                                      context: context,
                                      tx: tx,
                                      title: title,
                                      dateStr: dateStr,
                                      amount: amount,
                                      displayStatus: displayStatus,
                                      isWithdrawal: isWithdrawal,
                                      isRejected: isRejected,
                                      rejectionReason: rejectionReason,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: isRejected
                                                ? const Color(0xFFFECACA)
                                                : const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(5),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Icon Bubble
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: iconBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              itemIcon,
                                              color: iconColor,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Title & Date Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                                if (isRejected) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    (rejectionReason != null && rejectionReason.isNotEmpty)
                                                        ? 'Reason: $rejectionReason'
                                                        : (subtitle != null && !subtitle.toLowerCase().contains('under review')
                                                            ? subtitle
                                                            : 'Declined by Admin'),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Color(0xFFDC2626),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    '✓ 100% Refunded to Balance',
                                                    style: TextStyle(
                                                      color: Color(0xFF059669),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ] else if (subtitle != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    subtitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Color(0xFF64748B),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 3),
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Amount & Status Badge
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                isWithdrawal
                                                    ? '- ₹${amount.toStringAsFixed(2)}'
                                                    : '+ ₹${amount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: isWithdrawal
                                                      ? (isRejected || isDeduction
                                                          ? const Color(0xFFDC2626)
                                                          : const Color(0xFF0F172A))
                                                      : const Color(0xFF00875A),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _getStatusBg(displayStatus),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  displayStatus,
                                                  style: TextStyle(
                                                    color: _getStatusText(displayStatus),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9.5,
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
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails({
    required BuildContext context,
    required dynamic tx,
    required String title,
    required String dateStr,
    required double amount,
    required String displayStatus,
    required bool isWithdrawal,
    required bool isRejected,
    required String? rejectionReason,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),

            // Icon circle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRejected
                    ? const Color(0xFFFEE2E2)
                    : (isWithdrawal ? const Color(0xFFE0F2FE) : const Color(0xFFE6F4EA)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected
                    ? Icons.cancel_rounded
                    : (isWithdrawal ? Icons.arrow_upward_rounded : Icons.check_circle_rounded),
                color: isRejected
                    ? const Color(0xFFDC2626)
                    : (isWithdrawal ? const Color(0xFF0284C7) : const Color(0xFF00875A)),
                size: 36,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              isRejected
                  ? 'Withdrawal Declined'
                  : (isWithdrawal ? 'Withdrawal Payout' : 'Task Reward'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),

            // Amount
            Text(
              isWithdrawal
                  ? '- ₹${amount.toStringAsFixed(2)}'
                  : '+ ₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isRejected
                    ? const Color(0xFFDC2626)
                    : (isWithdrawal ? const Color(0xFF0F172A) : const Color(0xFF00875A)),
              ),
            ),
            const SizedBox(height: 8),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusBg(displayStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayStatus,
                style: TextStyle(
                  color: _getStatusText(displayStatus),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // If Declined: Prominent Reason & Refund Cards
            if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                        SizedBox(width: 6),
                        Text(
                          'Decline Reason',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rejectionReason != null && rejectionReason.isNotEmpty
                          ? rejectionReason
                          : 'Admin declined this withdrawal request. Please check your payment details or contact support.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F1D1D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹${amount.toStringAsFixed(2)} has been safely refunded to your Available Wallet Balance.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Transaction Info Table
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Description', title),
                  const Divider(height: 16),
                  _buildDetailRow('Date & Time', dateStr),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Destination',
                    (tx['metadata']?['paymentMethodId'] ?? tx['paymentMethodId'] ?? 'UPI / Bank Transfer').toString(),
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Reference ID',
                    (tx['referenceId'] ?? tx['id'] ?? 'N/A').toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
