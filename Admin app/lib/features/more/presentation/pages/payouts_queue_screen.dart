import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/more_models.dart';
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
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              AppAvatar(
                                                name: item.workerName,
                                                imageUrl: item.avatarUrl,
                                                userId: item.workerId,
                                                radius: 16,
                                                fontSize: 11,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.workerName.isNotEmpty ? item.workerName : 'Worker Account',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      item.workerEmail.isNotEmpty ? item.workerEmail : (item.workerId.length > 8 ? 'ID: #${item.workerId.substring(0, 8)}' : 'ID: ${item.workerId}'),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.gray500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showRejectDialog(context, item),
                                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                                      label: const Text(
                                        'Decline',
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<MoreBloc>().add(ProcessPayoutEvent(item.id));
                                      },
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                      label: const Text('Approve & Process'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
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

  void _showRejectDialog(BuildContext context, PayoutItemModel item) {
    String selectedReason = 'Invalid UPI ID / Bank account details';
    final customReasonController = TextEditingController();
    bool isCustom = false;

    final reasons = [
      'Invalid UPI ID / Bank account details',
      'Account holder name mismatch',
      'Suspicious / fraudulent activity detected',
      'KYC or identity verification required',
      'Other reason (type below)',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cancel_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Decline Withdrawal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decline payout of ₹${item.amount.toStringAsFixed(2)} for ${item.workerName.isNotEmpty ? item.workerName : 'Worker'}?',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select decline reason:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...reasons.map((r) => RadioListTile<String>(
                      title: Text(r, style: const TextStyle(fontSize: 12.5)),
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReason = val;
                            isCustom = val.startsWith('Other');
                          });
                        }
                      },
                    )),
                if (isCustom) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customReasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter specific decline reason...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The requested amount will be automatically refunded back to the worker\'s wallet balance.',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reasonToSubmit = isCustom
                    ? (customReasonController.text.trim().isNotEmpty
                        ? customReasonController.text.trim()
                        : 'Admin declined payout request')
                    : selectedReason;

                Navigator.pop(dialogContext);
                context.read<MoreBloc>().add(RejectPayoutEvent(item.id, reasonToSubmit));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payout declined. ₹${item.amount.toStringAsFixed(2)} refunded to worker.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Decline & Refund', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
