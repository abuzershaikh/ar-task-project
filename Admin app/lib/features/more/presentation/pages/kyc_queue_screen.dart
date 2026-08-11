import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class KycQueueScreen extends StatelessWidget {
  const KycQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Management Queue'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Pending', '12', AppColors.warning)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Verified', '245', AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Rejected', '8', AppColors.error)),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // KYC List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text('W${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Worker ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('W-${1000 + index}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        
                        _buildInfoRow('Full Name', 'Worker Name ${index + 1}'),
                        _buildInfoRow('DOB', '15 Jan 1995'),
                        _buildInfoRow('Document Type', 'Aadhaar Card'),
                        _buildInfoRow('Submitted', '${index + 1} hours ago'),
                        
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showDocumentViewer(context),
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('View Documents'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectKyc(context, index),
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
                                onPressed: () => _approveKyc(context, index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
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

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDocumentViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('KYC Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 300,
                color: AppColors.gray100,
                child: const Center(child: Text('Document Front Preview')),
              ),
              const SizedBox(height: 12),
              Container(
                height: 300,
                color: AppColors.gray100,
                child: const Center(child: Text('Document Back Preview')),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _approveKyc(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve KYC'),
        content: const Text('Mark this KYC verification as approved?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('KYC approved successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectKyc(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter rejection reason:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'INVALID_DOCUMENT', child: Text('Invalid Document')),
                DropdownMenuItem(value: 'POOR_QUALITY', child: Text('Poor Quality')),
                DropdownMenuItem(value: 'MISMATCH', child: Text('Information Mismatch')),
                DropdownMenuItem(value: 'EXPIRED', child: Text('Document Expired')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Additional Notes', border: OutlineInputBorder()),
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
                const SnackBar(content: Text('KYC rejected')),
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
