import 'package:flutter/material.dart';

/// Separate Transaction History Screen:
/// - Detailed list of past payout requests & earnings transactions with status filters.
/// - Styled with royal light blue & sapphire theme tokens.
class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _mockTransactions = [
    {
      'title': 'Payout to worker@upi',
      'date': '10 May 2025 • 11:45 AM',
      'amount': '100.00',
      'type': 'WITHDRAWAL',
      'status': 'Success',
    },
    {
      'title': 'Task Reward: Google Review',
      'date': '09 May 2025 • 04:15 PM',
      'amount': '15.00',
      'type': 'EARNING',
      'status': 'Success',
    },
    {
      'title': 'Payout to worker@upi',
      'date': '01 May 2025 • 03:20 PM',
      'amount': '200.00',
      'type': 'WITHDRAWAL',
      'status': 'Success',
    },
    {
      'title': 'Task Reward: YouTube Comment',
      'date': '28 Apr 2025 • 01:10 PM',
      'amount': '10.00',
      'type': 'EARNING',
      'status': 'Success',
    },
    {
      'title': 'Payout to worker@upi',
      'date': '20 Apr 2025 • 10:00 AM',
      'amount': '150.00',
      'type': 'WITHDRAWAL',
      'status': 'Success',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilter == 'All'
        ? _mockTransactions
        : _mockTransactions
            .where((tx) =>
                tx['type'] ==
                (_selectedFilter == 'Withdrawals' ? 'WITHDRAWAL' : 'EARNING'))
            .toList();

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
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
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

            // Transactions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final tx = filteredList[index];
                  final isWithdrawal = tx['type'] == 'WITHDRAWAL';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isWithdrawal
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFE6F4EA),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWithdrawal
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: isWithdrawal
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF00875A),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['title'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx['date'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isWithdrawal ? '- ₹${tx['amount']}' : '+ ₹${tx['amount']}',
                              style: TextStyle(
                                color: isWithdrawal
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF00875A),
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx['status'] as String,
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
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
          ],
        ),
      ),
    );
  }
}
