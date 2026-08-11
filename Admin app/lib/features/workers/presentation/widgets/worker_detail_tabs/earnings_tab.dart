import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class EarningsTab extends StatelessWidget {
  final String workerId;

  const EarningsTab({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildFinanceCard(
                  'Total Earned',
                  '₹45,200',
                  Icons.currency_rupee,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinanceCard(
                  'Available',
                  '₹3,500',
                  Icons.account_balance_wallet,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFinanceCard(
                  'Pending',
                  '₹1,200',
                  Icons.pending,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinanceCard(
                  'Withdrawn',
                  '₹40,500',
                  Icons.check_circle,
                  AppColors.info,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Transaction Stream
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              final isEarning = index % 3 != 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isEarning 
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEarning ? Icons.add_circle : Icons.remove_circle,
                      color: isEarning ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isEarning ? 'Task Approved' : 'Withdrawal',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isEarning ? 'Task #T-${10000 + index}' : 'To UPI: xxx@ybl',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isEarning ? '+' : '-'}₹${isEarning ? 15 : 500}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEarning ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        '${index + 1}d ago',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Withdrawal History
          const Text(
            'Withdrawal History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              final statuses = ['PAID', 'PROCESSING', 'REQUESTED', 'PAID', 'REJECTED'];
              final status = statuses[index];
              final colors = {
                'PAID': AppColors.success,
                'PROCESSING': AppColors.warning,
                'REQUESTED': AppColors.info,
                'REJECTED': AppColors.error,
              };
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'WD-${1000 + index}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors[status]!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors[status],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray500,
                                ),
                              ),
                              Text(
                                '₹${500 + (index * 100)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray900,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Method',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray500,
                                ),
                              ),
                              Text(
                                index % 2 == 0 ? 'UPI' : 'BANK',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (status == 'REQUESTED' || status == 'PROCESSING') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Mark Paid'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
