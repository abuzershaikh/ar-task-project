import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/more_bloc.dart';

class PayoutsQueueScreen extends StatefulWidget {
  const PayoutsQueueScreen({super.key});

  @override
  State<PayoutsQueueScreen> createState() => _PayoutsQueueScreenState();
}

class _PayoutsQueueScreenState extends State<PayoutsQueueScreen> {
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    context.read<MoreBloc>().add(LoadPayoutsQueueEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts Management'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MoreBloc>().add(LoadPayoutsQueueEvent()),
          ),
        ],
      ),
      body: BlocBuilder<MoreBloc, MoreState>(
        builder: (context, state) {
          if (state is MoreLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MoreError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<MoreBloc>().add(LoadPayoutsQueueEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PayoutsQueueLoaded) {
            final items = state.items;

            if (items.isEmpty) {
              return const Center(child: Text('No pending payouts in queue'));
            }

            final totalPendingAmount = items.fold(0.0, (sum, i) => sum + i.amount);

            return Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.white,
                  child: Row(
                    children: [
                      Expanded(child: _buildSummaryCard('Pending Requests', '${items.length}', '₹${totalPendingAmount.toStringAsFixed(2)}', AppColors.warning)),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Payout List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = _selectedItems.contains(item.id);

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
                                          _selectedItems.add(item.id);
                                        } else {
                                          _selectedItems.remove(item.id);
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
                                              'ID: ${item.id}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.gray500,
                                              ),
                                            ),
                                            Text(
                                              item.status,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.workerName.isNotEmpty ? item.workerName : 'Worker ${item.workerId}',
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
                                        '₹${item.amount.toStringAsFixed(2)}',
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
                                          item.paymentMethod,
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
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context.read<MoreBloc>().add(ProcessPayoutEvent(item.id));
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                      child: const Text('Approve & Process'),
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
            );
          }

          return const SizedBox();
        },
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
}
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
