import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class TaskReviewInspectorModal extends StatelessWidget {
  final String taskId;
  final String workerId;

  const TaskReviewInspectorModal({
    super.key,
    required this.taskId,
    required this.workerId,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Review Inspector',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$taskId • Worker: $workerId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Submission Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.person, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Worker Name', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Quality Score: 92.5', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: const Text(
                                  'High Quality',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildInfoRow('Task ID', taskId),
                          _buildInfoRow('Submitted', '2 hours ago'),
                          _buildInfoRow('Time Taken', '8 minutes'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Proof Inspector
                  const Text('Submission Proof', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screenshot Preview
                        Container(
                          height: 300,
                          width: double.infinity,
                          color: AppColors.gray100,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 64, color: AppColors.gray400),
                                SizedBox(height: 8),
                                Text('Screenshot Preview', style: TextStyle(color: AppColors.gray600)),
                                Text('(Tap to zoom)', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                              ],
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.zoom_in, size: 18),
                                    label: const Text('View Full Size'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Download'),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              const Text('Submitted URL:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'https://youtube.com/watch?v=example123',
                                        style: TextStyle(fontSize: 13, color: AppColors.primary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18),
                                      onPressed: () {
                                        Clipboard.setData(const ClipboardData(text: 'https://youtube.com/watch?v=example123'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('URL copied to clipboard')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              const Text('Comments/Notes:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text(
                                'Completed the task successfully. Liked the video and left a positive comment.',
                                style: TextStyle(color: AppColors.gray700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Review Decision Buttons
                  const Text('Review Decision', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(context),
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text('Approve Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRejectDialog(context),
                          icon: const Icon(Icons.cancel, size: 20),
                          label: const Text('Reject Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
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
          Text(label, style: const TextStyle(color: AppColors.gray600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task'),
        content: const Text('This will mark the task as approved and post earnings to the worker.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task approved successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    String? selectedReason;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select rejection reason:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Reason Code',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'INVALID_PROOF', child: Text('Invalid Proof')),
                DropdownMenuItem(value: 'INCOMPLETE_STEP', child: Text('Incomplete Steps')),
                DropdownMenuItem(value: 'DUPLICATE_SUBMISSION', child: Text('Duplicate Submission')),
                DropdownMenuItem(value: 'POOR_QUALITY', child: Text('Poor Quality')),
              ],
              onChanged: (value) => selectedReason = value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Provide detailed feedback',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task rejected')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
