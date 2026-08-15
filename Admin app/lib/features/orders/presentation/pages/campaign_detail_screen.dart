import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/orders_bloc.dart';
import '../widgets/task_review_inspector_modal.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String orderId;

  const CampaignDetailScreen({super.key, required this.orderId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadOrderDetailEvent(widget.orderId));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderId),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pause', child: Text('Pause Campaign')),
              const PopupMenuItem(value: 'resume', child: Text('Resume Campaign')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancel & Refund')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrdersBloc>().add(LoadOrderDetailEvent(widget.orderId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = state is OrderDetailLoaded ? state.order : null;
          final tasks = state is OrderDetailLoaded ? state.tasks : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Campaign Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(order?.serviceType ?? 'Task Campaign', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Status: ${order?.status ?? "ACTIVE"}', style: const TextStyle(color: AppColors.gray600)),
                        const SizedBox(height: 16),
                        _buildInfoRow('Buyer ID', order?.buyerId ?? 'N/A'),
                        _buildInfoRow('Service Type', order?.serviceType ?? 'N/A'),
                        _buildInfoRow('Reward/Task', '₹${order?.rewardPerTask ?? 0.0}'),
                        _buildInfoRow('Total Tasks', '${order?.totalTasksRequired ?? 0}'),
                        _buildInfoRow('Completed Tasks', '${order?.tasksCompleted ?? 0}'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Task Generation Matrix
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Task Generation Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total Required', '${order?.totalTasksRequired ?? 0}', AppColors.primary)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard('Completed', '${order?.tasksCompleted ?? 0}', AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Pending Tasks', '${tasks.length}', AppColors.warning)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard('Total Spent', '₹${order?.totalAmount ?? 0.0}', AppColors.info)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Submissions List
                const Text('Task Submissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No task submissions found for this campaign.')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final item = tasks[index];
                      final taskId = item['id']?.toString() ?? 'T-${1000 + index}';
                      final workerId = item['workerId']?.toString() ?? 'W-${100 + index}';
                      final status = (item['status']?.toString() ?? 'PENDING').toUpperCase();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text('W${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          title: Text('Task #$taskId'),
                          subtitle: Text('Worker: $workerId'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => TaskReviewInspectorModal(
                                taskId: taskId,
                                workerId: workerId,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.gray600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
      case 'COMPLETED':
        return AppColors.success;
      case 'PENDING':
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  void _handleAction(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_getActionTitle(action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getActionMessage(action)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Required)',
                hintText: 'Enter reason for this action',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (action == 'pause') {
                context.read<OrdersBloc>().add(PauseOrderEvent(widget.orderId));
              } else if (action == 'resume') {
                context.read<OrdersBloc>().add(ResumeOrderEvent(widget.orderId));
              } else if (action == 'cancel') {
                context.read<OrdersBloc>().add(CancelOrderEvent(orderId: widget.orderId, reason: _reasonController.text.trim()));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'pause': return 'Pause Campaign';
      case 'resume': return 'Resume Campaign';
      case 'cancel': return 'Cancel & Refund';
      default: return '';
    }
  }

  String _getActionMessage(String action) {
    switch (action) {
      case 'pause': return 'This will pause task allocation. Workers can still complete assigned tasks.';
      case 'resume': return 'This will resume task allocation to eligible workers.';
      case 'cancel': return 'This will cancel the campaign and refund unused budget to the buyer.';
      default: return '';
    }
  }
}
      default: return '';
    }
  }
}
