import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/review_submission_model.dart';
import '../../data/repositories/review_repository.dart';

/// ReviewDetailPage - Worker Task Proof Verification & Approval Screen
/// Is page par Buyer worker dwara submit kiya hua real task proof (Screenshot / Text proof) review karke Approve ya Reject karta hai.
class ReviewDetailPage extends StatefulWidget {
  final String submissionId;
  final ReviewSubmissionModel? initialSubmission;

  const ReviewDetailPage({
    super.key,
    required this.submissionId,
    this.initialSubmission,
  });

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  bool _isLoading = false;
  bool _isProcessing = false;
  String _status = 'PENDING';
  ReviewSubmissionModel? _submission;
  
  late final ReviewRepository _reviewRepo;

  @override
  void initState() {
    super.initState();
    _reviewRepo = getIt<ReviewRepository>();
    if (widget.initialSubmission != null) {
      _submission = widget.initialSubmission;
      _status = widget.initialSubmission!.status;
    }
    _loadSubmissionDetail();
  }

  Future<void> _loadSubmissionDetail() async {
    if (_submission == null) {
      setState(() => _isLoading = true);
    }
    final result = await _reviewRepo.getReviewDetail(widget.submissionId);
    if (!mounted) return;

    result.fold(
      (failure) {
        if (_submission == null) {
          setState(() => _isLoading = false);
        }
      },
      (detail) {
        setState(() {
          _isLoading = false;
          _submission = detail;
          _status = detail.status;
        });
      },
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Worker task proof approval handler function
  void _approveTaskProof() async {
    setState(() => _isProcessing = true);
    final result = await _reviewRepo.approveTaskProof(widget.submissionId);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve proof: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (success) {
        if (success) {
          setState(() {
            _isProcessing = false;
            _status = 'APPROVED';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task approved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
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
              final result = await _reviewRepo.rejectTaskProof(
                widget.submissionId, 
                'INVALID_PROOF', 
                reasonController.text.isNotEmpty ? reasonController.text : 'Submission rejected by buyer',
              );
              if (!mounted) return;

              result.fold(
                (failure) {
                  setState(() => _isProcessing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reject proof: ${failure.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                (success) {
                  if (success) {
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
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _submission == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text('Proof Review #${widget.submissionId.length > 8 ? widget.submissionId.substring(0, 8) : widget.submissionId}'),
          backgroundColor: const Color(0xFF0F172A),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    final taskTitle = _submission?.taskTitle.isNotEmpty == true ? _submission!.taskTitle : 'Task Submission';
    final workerName = _submission?.workerName.isNotEmpty == true ? _submission!.workerName : 'Worker';
    final workerId = _submission?.workerId ?? '';
    final proofUrl = _submission?.proofScreenshotUrl ?? '';
    final proofText = _submission?.proofText ?? '';
    final submittedDateStr = _submission?.submittedAt != null
        ? '${_submission!.submittedAt.day}/${_submission!.submittedAt.month}/${_submission!.submittedAt.year} ${_submission!.submittedAt.hour.toString().padLeft(2, '0')}:${_submission!.submittedAt.minute.toString().padLeft(2, '0')}'
        : 'Recent';

    final bool isApproved = _status == 'APPROVED';
    final bool isRejected = _status == 'REJECTED';
    final bool isPending = !isApproved && !isRejected;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Proof Review #${widget.submissionId.length > 8 ? widget.submissionId.substring(0, 8) : widget.submissionId}'),
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
                      Expanded(
                        child: Text(
                          taskTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? Colors.green.withOpacity(0.2)
                              : isRejected
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.amberAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: isApproved
                                ? Colors.greenAccent
                                : isRejected
                                    ? Colors.redAccent
                                    : Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Worker: $workerName ${workerId.isNotEmpty ? '($workerId)' : ''}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text('Submitted At: $submittedDateStr', style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Worker Text Proof Card (if available)
          if (proofText.isNotEmpty) ...[
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Worker Submitted Text / Notes:', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        proofText,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Worker Proof Screenshot Card
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
                      const Text('Worker Submitted Screenshot Proof:', style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      if (proofUrl.isNotEmpty && proofUrl.startsWith('http'))
                        TextButton.icon(
                          onPressed: () => _showFullScreenImage(proofUrl),
                          icon: const Icon(Icons.zoom_in_rounded, color: Colors.cyanAccent, size: 18),
                          label: const Text('Zoom', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      if (proofUrl.isNotEmpty && proofUrl.startsWith('http')) {
                        _showFullScreenImage(proofUrl);
                      }
                    },
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: proofUrl.isNotEmpty && proofUrl.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    proofUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (c, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                                    },
                                    errorBuilder: (c, err, stack) => const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_rounded, size: 48, color: Colors.white38),
                                          SizedBox(height: 6),
                                          Text('Failed to load image', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_rounded, size: 54, color: Colors.white38),
                                SizedBox(height: 8),
                                Text('No Screenshot Uploaded', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Approve / Reject
          if (isPending) ...[
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
                    label: Text(_isProcessing ? 'Processing...' : 'Approve Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _isProcessing ? null : _approveTaskProof,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isApproved ? Colors.greenAccent : Colors.redAccent),
              ),
              child: Text(
                isApproved ? '✓ Task approved successfully.' : '✗ Task proof has been rejected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isApproved ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
