import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// ReviewDetailPage - Worker Task Proof Verification & Approval Screen
/// Is page par Buyer worker dwara submit kiya hua task proof (Screenshot / Text proof) review karke Approve ya Reject karta hai.
class ReviewDetailPage extends StatefulWidget {
  final String submissionId;

  const ReviewDetailPage({super.key, required this.submissionId});

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  bool _isProcessing = false;
  String _status = 'PENDING';

  /// Worker task proof approval handler function
  void _approveTaskProof() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _status = 'APPROVED';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task proof approved! Worker reward released.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// Worker task proof rejection handler function (opens reason dialog)
  void _rejectTaskProof() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Task Submission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this worker\'s proof:', style: TextStyle(fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Screenshot blurry / Channel subscribe not visible',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Reject'),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              await Future.delayed(const Duration(milliseconds: 800));
              if (!mounted) return;

              setState(() {
                _isProcessing = false;
                _status = 'REJECTED';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task proof rejected with feedback.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Proof Review #${widget.submissionId}'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Submission Summary Header Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('YouTube Channel Subscribe Task', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _status == 'APPROVED'
                              ? Colors.green.withOpacity(0.2)
                              : _status == 'REJECTED'
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.amberAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status == 'APPROVED'
                                ? Colors.greenAccent
                                : _status == 'REJECTED'
                                    ? Colors.redAccent
                                    : Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Worker ID: WRK_894021', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text('Submitted At: 12 Aug 2026, 04:30 PM', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Worker Proof Screenshot Card
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Worker Submitted Screenshot Proof:', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_rounded, size: 54, color: Colors.white38),
                        SizedBox(height: 8),
                        Text('Proof Screenshot Attachment Preview', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('YouTube Subscribed Badge Visible', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Approve / Reject
          if (_status == 'PENDING') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_rounded, size: 20),
                    label: const Text('Reject Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isProcessing ? null : _rejectTaskProof,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(_isProcessing ? 'Processing...' : 'Approve & Release', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isProcessing ? null : _approveTaskProof,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _status == 'APPROVED' ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _status == 'APPROVED' ? Colors.greenAccent : Colors.redAccent),
              ),
              child: Text(
                _status == 'APPROVED' ? '✓ Task proof has been approved and payout released.' : '✗ Task proof has been rejected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _status == 'APPROVED' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
