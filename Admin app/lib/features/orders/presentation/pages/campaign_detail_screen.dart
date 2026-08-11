import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/task_review_inspector_modal.dart';

class CampaignDetailScreen extends StatelessWidget {
  final String orderId;

  const CampaignDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(orderId),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pause', child: Text('Pause Campaign')),
              const PopupMenuItem(value: 'resume', child: Text('Resume Campaign')),
              const PopupMenuItem(value: 'extend', child: Text('Extend Expiry')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancel & Refund')),
              const PopupMenuItem(value: 'reallocate', child: Text('Force Reallocate')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    const Text('YouTube Like Campaign - Tech Channel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Description: Like and engage with tech videos', style: TextStyle(color: AppColors.gray600)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Buyer', 'ABC Digital Pvt Ltd'),
                    _buildInfoRow('Task Type', 'YOUTUBE_LIKE'),
                    _buildInfoRow('Review Mode', 'AUTO'),
                    _buildInfoRow('Created', '5 days ago'),
                    _buildInfoRow('Expires', 'In 2 days'),
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
                        Expanded(child: _buildStatCard('Total Required', '1000', AppColors.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Generated', '1000', AppColors.info)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Available', '150', AppColors.warning)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Assigned', '400', AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Completed', '450', AppColors.success)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Expired', '0', AppColors.error)),
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
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                final statuses = ['APPROVED', 'PENDING', 'REJECTED', 'APPROVED', 'PENDING'];
                final status = statuses[index % statuses.length];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text('W${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('Task #T-${10000 + index}'),
                    subtitle: Text('Worker W-${1000 + index} • ${index + 1}h ago'),
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
                          taskId: 'T-${10000 + index}',
                          workerId: 'W-${1000 + index}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
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
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  void _handleAction(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActionTitle(action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getActionMessage(action)),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Reason (Required)',
                hintText: 'Enter reason for this action',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm')),
        ],
      ),
    );
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'pause': return 'Pause Campaign';
      case 'resume': return 'Resume Campaign';
      case 'extend': return 'Extend Expiry';
      case 'cancel': return 'Cancel & Refund';
      case 'reallocate': return 'Force Reallocate';
      default: return '';
    }
  }

  String _getActionMessage(String action) {
    switch (action) {
      case 'pause': return 'This will pause task allocation. Workers can still complete assigned tasks.';
      case 'resume': return 'This will resume task allocation to eligible workers.';
      case 'extend': return 'Enter new expiry date for this campaign.';
      case 'cancel': return 'This will cancel the campaign and refund unused budget to the buyer.';
      case 'reallocate': return 'This will force reallocate all pending tasks to new workers.';
      default: return '';
    }
  }
}
