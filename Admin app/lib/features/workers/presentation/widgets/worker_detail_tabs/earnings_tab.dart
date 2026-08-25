import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/worker_model.dart';

class EarningsTab extends StatelessWidget {
  final WorkerModel worker;
  final List<dynamic> earnings;

  const EarningsTab({
    super.key,
    required this.worker,
    this.earnings = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildFinanceCard(
                  'Total Earned',
                  '₹${worker.totalEarnings.toStringAsFixed(2)}',
                  Icons.currency_rupee_rounded,
                  const Color(0xFF0284C7),
                  const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFinanceCard(
                  'Completed Tasks',
                  '${worker.completedTasks}',
                  Icons.task_alt_rounded,
                  const Color(0xFF16A34A),
                  const Color(0xFFDCFCE7),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Transaction Stream
          const Row(
            children: [
              Icon(Icons.history_edu_rounded, size: 18, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Earnings & Payout Stream',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          earnings.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 40, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text(
                        'No payout records recorded yet',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: earnings.length,
                  itemBuilder: (context, index) {
                    final item = earnings[index];
                    final amount = item['amount'] != null ? '₹${item['amount']}' : '₹0.00';
                    final description = item['description'] ?? item['title'] ?? 'Task Completion Reward';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: Color(0xFF16A34A),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          description.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        trailing: Text(
                          amount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String title, String amount, IconData icon, Color color, Color bgColor) {
    return Container(
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
