import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/review_submission_model.dart';
import '../../data/repositories/review_repository.dart';

/// ReviewDetailPage - Worker Task Proof Verification & Approval Screen
/// Styled in modern White & Violet theme (#FAF5FF, #FFFFFF, #7C3AED, #6D28D9, #1E1B4B).
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
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 44,
              right: 18,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(ctx),
                ),
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
            backgroundColor: const Color(0xFFDC2626),
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
              content: Text('Task approved successfully! Worker paid.'),
              backgroundColor: Color(0xFF059669),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Reject Submission',
              style: GoogleFonts.outfit(
                color: const Color(0xFF1E1B4B),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide clear feedback so worker understands why the proof was declined:',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E1B4B)),
              decoration: InputDecoration(
                hintText: 'e.g. Screenshot blurry / required action not visible in screenshot',
                hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFFAF5FF),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE9FE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE9FE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Confirm Reject',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
            ),
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
                      backgroundColor: const Color(0xFFDC2626),
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
                        backgroundColor: Color(0xFFDC2626),
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
    final shortId = widget.submissionId.length > 8
        ? widget.submissionId.substring(0, 8).toUpperCase()
        : widget.submissionId;

    if (_isLoading && _submission == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF5FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF6D28D9)),
          title: Text(
            'Proof Review #$shortId',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E1B4B),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFEDE9FE), height: 1),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
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
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6D28D9)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proof Review',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E1B4B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '#$shortId',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF7C3AED),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEDE9FE), height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
          // 1. Submission Summary Header Card (Pure White with Violet Accents)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        taskTitle,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E1B4B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? const Color(0xFFECFDF5)
                            : isRejected
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isApproved
                              ? const Color(0xFFA7F3D0)
                              : isRejected
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFDDD6FE),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApproved
                                ? Icons.check_circle_rounded
                                : isRejected
                                    ? Icons.cancel_rounded
                                    : Icons.hourglass_top_rounded,
                            size: 12,
                            color: isApproved
                                ? const Color(0xFF059669)
                                : isRejected
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isApproved
                                ? 'APPROVED'
                                : isRejected
                                    ? 'REJECTED'
                                    : 'UNDER REVIEW',
                            style: GoogleFonts.outfit(
                              color: isApproved
                                  ? const Color(0xFF059669)
                                  : isRejected
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF7C3AED),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  workerName,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1E1B4B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (workerId.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${workerId.length > 8 ? workerId.substring(0, 8) : workerId})',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 4),
                                Text(
                                  'Submitted: $submittedDateStr',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Worker Text Proof Card (if available)
          if (proofText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notes_rounded, size: 16, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Worker Notes & Details',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E1B4B),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEDE9FE)),
                    ),
                    child: Text(
                      proofText,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1F2937),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Worker Screenshot Proof Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image_outlined, size: 16, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Screenshot Proof',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1E1B4B),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (proofUrl.isNotEmpty && proofUrl.startsWith('http'))
                      GestureDetector(
                        onTap: () => _showFullScreenImage(proofUrl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in_rounded, color: Color(0xFF7C3AED), size: 15),
                              const SizedBox(width: 4),
                              Text(
                                'Zoom',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF7C3AED),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    if (proofUrl.isNotEmpty && proofUrl.startsWith('http')) {
                      _showFullScreenImage(proofUrl);
                    }
                  },
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
                    ),
                    child: proofUrl.isNotEmpty && proofUrl.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  proofUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (c, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                                    );
                                  },
                                  errorBuilder: (c, err, stack) => Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFFA78BFA)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load proof image',
                                          style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1B4B).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.zoom_in, color: Colors.white, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap to expand',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF3E8FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.image_not_supported_rounded, size: 40, color: Color(0xFF7C3AED)),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No Screenshot Uploaded',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Action Buttons: Approve / Reject
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      'Reject Proof',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: _isProcessing ? null : _rejectTaskProof,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _approveTaskProof,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isProcessing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _isProcessing ? 'Processing...' : 'Approve Task',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isApproved ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isApproved ? Icons.verified_rounded : Icons.cancel_rounded,
                    color: isApproved ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isApproved ? 'Task approved successfully • Worker credited' : 'Task proof has been rejected with feedback',
                    style: GoogleFonts.outfit(
                      color: isApproved ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
  }
}
