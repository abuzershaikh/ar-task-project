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

                                // Choose appropriate icon & icon background
                                IconData itemIcon;
                                Color iconColor;
                                Color iconBg;

                                if (isDeduction) {
                                  itemIcon = Icons.remove_circle_outline_rounded;
                                  iconColor = const Color(0xFFDC2626);
                                  iconBg = const Color(0xFFFEE2E2);
                                } else if (isWithdrawal) {
                                  itemIcon = Icons.arrow_upward_rounded;
                                  iconColor = const Color(0xFF0284C7);
                                  iconBg = const Color(0xFFE0F2FE);
                                } else {
                                  itemIcon = Icons.arrow_downward_rounded;
                                  iconColor = const Color(0xFF00875A);
                                  iconBg = const Color(0xFFE6F4EA);
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
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
                                            if (subtitle != null) ...[
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
                                                  ? (isDeduction
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
                                              color: _getStatusBg(status),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _getStatusText(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
}
