import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  String _formatId(String id) {
    if (id.length <= 12) return id;
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

  Widget _buildCopySnippet(BuildContext context, String label, String fullId) {
    if (fullId.isEmpty) return const Text('N/A', style: TextStyle(color: Color(0xFF64748B)));
    return InkWell(
      onTap: () => _copyToClipboard(context, fullId, label),
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
            Text(
              _formatId(fullId),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text(
          _formatId(widget.orderId),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
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
          if (state is OrdersLoading || state is OrderDetailLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
                  const SizedBox(height: 8),
                  Text(state.message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<OrdersBloc>().add(LoadOrderDetailEvent(widget.orderId));
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          }

          final order = state is OrderDetailLoaded ? state.order : null;
          final tasks = state is OrderDetailLoaded ? state.tasks : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Card
                Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF059669)),
                                SizedBox(width: 8),
                                Text(
                                  'Campaign Information',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
                              ),
                              child: Text(
                                order?.status ?? 'ACTIVE',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                        const SizedBox(height: 12),
                        Text(
                          order?.campaignName ?? 'Campaign Title',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                        ),
                        const SizedBox(height: 12),
                        _buildCustomRow('Campaign ID', _buildCopySnippet(context, 'Campaign ID', order?.id ?? widget.orderId)),
                        _buildInfoRow('Buyer Name', order?.buyerName.isNotEmpty == true ? order!.buyerName : 'Direct Buyer'),
                        if (order?.buyerEmail.isNotEmpty == true)
                          _buildInfoRow('Buyer Email', order!.buyerEmail),
                        _buildCustomRow('Buyer UID', _buildCopySnippet(context, 'Buyer UID', order?.buyerId ?? '')),
                        _buildInfoRow('Service Type', order?.serviceType ?? 'General Task'),
                        _buildInfoRow('Worker Reward / Task', '₹${(order?.rewardPerTask ?? 0.0).toStringAsFixed(2)}'),
                        _buildInfoRow('Total Required Tasks', '${order?.totalTasks ?? 0} Tasks'),
                        _buildInfoRow('Completed Tasks', '${order?.completedTasks ?? 0} Tasks'),
                        _buildInfoRow('Total Campaign Budget', '₹${(order?.totalBudget ?? 0.0).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Task Generation Matrix Card
                Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text(
                              'Task Allocation Matrix',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Total Tasks', '${order?.totalTasks ?? 0}', const Color(0xFF059669))),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Completed', '${order?.completedTasks ?? 0}', const Color(0xFF16A34A))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Submissions', '${tasks.length}', const Color(0xFFD97706))),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Total Budget', '₹${(order?.totalBudget ?? 0.0).toStringAsFixed(0)}', const Color(0xFF0284C7))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Submissions List
                const Row(
                  children: [
                    Icon(Icons.assignment_turned_in_rounded, size: 18, color: Color(0xFF059669)),
                    SizedBox(width: 8),
                    Text(
                      'Task Proof Submissions',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (tasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 44, color: Color(0xFF94A3B8)),
                        SizedBox(height: 10),
                        Text(
                          'No worker task submissions recorded for this campaign yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final item = tasks[index];
                      final taskId = item['id']?.toString() ?? 'T-${1000 + index}';
                      final workerId = item['workerId']?.toString() ?? item['assignedTo']?.toString() ?? 'W-${100 + index}';
                      final workerName = item['workerName'] ?? item['worker']?['name'] ?? (item['workerEmail'] != null ? item['workerEmail'].toString().split('@').first : (workerId.length > 6 ? 'Worker #${workerId.substring(0, 6)}' : workerId));
                      final workerEmail = item['workerEmail'] ?? item['worker']?['email'] ?? '';
                      final status = (item['status']?.toString() ?? 'PENDING').toUpperCase();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFECFDF5),
                            child: Text(
                              workerName.toString().isNotEmpty ? workerName.toString().substring(0, 1).toUpperCase() : 'W',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  workerName.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF064E3B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildCopySnippet(context, 'Task ID', taskId),
                            ],
                          ),
                          subtitle: Text(
                            workerEmail.isNotEmpty ? workerEmail : 'Worker ID: ${_formatId(workerId)}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _getStatusBg(status),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF059669)),
                            ],
                          ),
                          onTap: () {
                            final submissionId = item['submissionId']?.toString() ?? item['id']?.toString() ?? '';
                            String proofUrl = (item['proofUrl'] ?? item['proofScreenshotUrl'] ?? '').toString();
                            if (proofUrl.isEmpty && item['proofs'] is List && (item['proofs'] as List).isNotEmpty) {
                              final p0 = (item['proofs'] as List).first;
                              if (p0 is Map) proofUrl = (p0['url'] ?? p0['path'] ?? '').toString();
                              else if (p0 is String) proofUrl = p0;
                            }
                            if (proofUrl.isEmpty && item['data'] is Map) {
                              proofUrl = (item['data']['proofUrl'] ?? item['data']['screenshotUrl'] ?? '').toString();
                            }
                            String proofText = (item['proofText'] ?? item['notes'] ?? '').toString();
                            if (proofText.isEmpty && item['data'] is Map) {
                              proofText = (item['data']['textProof'] ?? item['data']['proofText'] ?? item['data']['notes'] ?? '').toString();
                            }

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => TaskReviewInspectorModal(
                                submissionId: submissionId,
                                taskId: taskId,
                                workerId: workerId,
                                workerName: workerName.toString(),
                                workerEmail: workerEmail.toString(),
                                proofUrl: proofUrl.isNotEmpty ? proofUrl : null,
                                proofText: proofText.isNotEmpty ? proofText : null,
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
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF064E3B))),
        ],
      ),
    );
  }

  Widget _buildCustomRow(String label, Widget rightWidget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w500)),
          rightWidget,
        ],
      ),
    );
  }


  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
      case 'COMPLETED':
        return const Color(0xFF16A34A);
      case 'PENDING':
      case 'IN_PROGRESS':
        return const Color(0xFFD97706);
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'APPROVED':
      case 'COMPLETED':
        return const Color(0xFFDCFCE7);
      case 'PENDING':
      case 'IN_PROGRESS':
        return const Color(0xFFFEF3C7);
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  void _handleAction(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(_getActionTitle(action), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getActionMessage(action), style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Required)',
                hintText: 'Enter reason for this action',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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

