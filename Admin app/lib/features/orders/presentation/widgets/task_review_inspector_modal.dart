import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';

class TaskReviewInspectorModal extends StatelessWidget {
  final String submissionId;
  final String taskId;
  final String workerId;
  final String workerName;
  final String workerEmail;
  final String? proofUrl;
  final String? proofText;

  const TaskReviewInspectorModal({
    super.key,
    this.submissionId = '',
    required this.taskId,
    required this.workerId,
    this.workerName = '',
    this.workerEmail = '',
    this.proofUrl,
    this.proofText,
  });

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
    final displayName = workerName.isNotEmpty ? workerName : (workerId.length > 6 ? 'Worker #${workerId.substring(0, 6)}' : workerId);

    String? normalizedProofUrl = proofUrl;
    if (normalizedProofUrl != null && normalizedProofUrl.isNotEmpty && !normalizedProofUrl.startsWith('http')) {
      final clean = normalizedProofUrl.startsWith('/') ? normalizedProofUrl : '/$normalizedProofUrl';
      normalizedProofUrl = clean.contains('/files/raw')
          ? 'http://65.20.77.112:3000$clean'
          : 'http://65.20.77.112:3000/api/v1/files/raw/$normalizedProofUrl';
    }

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
                        const Text(
                          'Task Review Inspector',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                        Text(
                          workerEmail.isNotEmpty ? 'Worker: $displayName ($workerEmail)' : 'Worker: $displayName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08059669),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                                    ),
                                    Text(
                                      workerEmail.isNotEmpty ? workerEmail : 'ID: $workerId',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          _buildCustomRow(context, 'Task ID', _buildCopySnippet(context, 'Task ID', taskId)),
                          if (submissionId.isNotEmpty)
                            _buildCustomRow(context, 'Submission ID', _buildCopySnippet(context, 'Submission ID', submissionId)),
                          _buildCustomRow(context, 'Worker ID', _buildCopySnippet(context, 'Worker ID', workerId)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Text Proof (if available)
                  if (proofText != null && proofText!.isNotEmpty) ...[
                    const Text('Worker Submitted Text / Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        proofText!,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Proof Inspector
                  const Text('Submission Proof Screenshot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                  const SizedBox(height: 10),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screenshot Preview
                        InkWell(
                          onTap: () {
                            if (normalizedProofUrl != null && normalizedProofUrl.isNotEmpty) {
                              ImageViewerDialog.show(context, imageUrl: normalizedProofUrl, title: 'Proof Screenshot');
                            }
                          },
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            color: AppColors.gray100,
                            child: normalizedProofUrl != null && normalizedProofUrl.startsWith('http')
                                ? Image.network(
                                    normalizedProofUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                    errorBuilder: (ctx, err, stack) => const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                          SizedBox(height: 6),
                                          Text('Failed to load image', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 64, color: AppColors.gray400),
                                        SizedBox(height: 8),
                                        Text('Screenshot Preview', style: TextStyle(color: AppColors.gray600)),
                                        Text('(Tap to view full screen)', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                                      ],
                                    ),
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
                                    onPressed: () {
                                      if (normalizedProofUrl != null && normalizedProofUrl.isNotEmpty) {
                                        ImageViewerDialog.show(context, imageUrl: normalizedProofUrl, title: 'Proof Screenshot');
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No image URL available')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.zoom_in, size: 18),
                                    label: const Text('View Full Size (Zoom)'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
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
                            foregroundColor: Colors.white,
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
                            foregroundColor: Colors.white,
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
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF064E3B))),
        ],
      ),
    );
  }

  Widget _buildCustomRow(BuildContext context, String label, Widget rightWidget) {
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

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Task'),
        content: const Text('This will mark the task submission as approved and credit earnings to worker.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final targetId = submissionId.isNotEmpty ? submissionId : taskId;
              try {
                final dio = getIt<DioClient>();
                await dio.post('/admin/reviews/$targetId/approve');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission approved successfully! Reward credited to worker.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to approve: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    String? selectedReason;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              controller: notesController,
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final targetId = submissionId.isNotEmpty ? submissionId : taskId;
              try {
                final dio = getIt<DioClient>();
                await dio.post(
                  '/admin/reviews/$targetId/reject',
                  data: {
                    'reason': selectedReason ?? 'INVALID_PROOF',
                    'notes': notesController.text,
                  },
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Submission rejected.'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reject: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

