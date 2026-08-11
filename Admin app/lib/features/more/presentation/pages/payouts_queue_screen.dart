import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PayoutsQueueScreen extends StatefulWidget {
  const PayoutsQueueScreen({super.key});

  @override
  State<PayoutsQueueScreen> createState() => _PayoutsQueueScreenState();
}

class _PayoutsQueueScreenState extends State<PayoutsQueueScreen> {
  final Set<int> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts Management'),
        backgroundColor: AppColors.primary,
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton.icon(
              onPressed: _bulkApprove,
              icon: const Icon(Icons.check_circle, color: AppColors.white),
              label: Text(
                'Approve ${_selectedItems.length}',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(child: _buildSummaryCard('Pending', '23', '₹45,600', AppColors.warning)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Processing', '5', '₹12,500', AppColors.info)),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Payout List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 20,
              itemBuilder: (context, index) {
                final isSelected = _selectedItems.contains(index);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedItems.add(index);
                                  } else {
                                    _selectedItems.remove(index);
                                  }
                                });
                              },
                            ),
                            Expanded(
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
                                      Text(
                                        '${index + 1}h ago',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Worker W-${1000 + index}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amount', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                                Text(
                                  '₹${500 + (index * 100)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Method', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    index % 2 == 0 ? 'UPI' : 'BANK',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectPayout(index),
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
                                onPressed: () => _approvePayout(index),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String count, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(amount, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }

  void _approvePayout(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payout'),
        content: const Text('Mark this payout as approved and processed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout approved')),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectPayout(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter rejection reason:'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout rejected')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _bulkApprove() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Approve'),
        content: Text('Approve ${_selectedItems.length} selected payouts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedItems.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payouts approved successfully')),
              );
            },
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }
}
