import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/review_submission_model.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/services/review_auto_approve_config_service.dart';

/// ReviewDetailPage - Reels-Style Vertical Swipe Worker Proof Reviewer
/// - Vertical PageView ("Reel style" swipe up/down for next/prev worker proof)
/// - Top "Approve All" bulk review button with instant confirmation
/// - Interactive proof image zoom & expand
/// - Worker details, notes/text proof, and 1-tap Approve / Reject actions
/// - Auto-advances to next proof on action
class ReviewDetailPage extends StatefulWidget {
  final String submissionId;
  final ReviewSubmissionModel? initialSubmission;
  final List<ReviewSubmissionModel>? allSubmissions;
  final int initialIndex;
  final String? campaignId;

  const ReviewDetailPage({
    super.key,
    required this.submissionId,
    this.initialSubmission,
    this.allSubmissions,
    this.initialIndex = 0,
    this.campaignId,
  });

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  late PageController _pageController;
  late final ReviewRepository _reviewRepo;

  List<ReviewSubmissionModel> _submissions = [];
  final Map<String, String> _statuses = {};
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isProcessing = false;
  double _autoApproveHours = ReviewAutoApproveConfigService.getCachedHoursSync();

  @override
  void initState() {
    super.initState();
    _reviewRepo = getIt<ReviewRepository>();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Fetch review auto-approve hours (cached for 7 days in SharedPreferences, 24h fallback)
    ReviewAutoApproveConfigService.getAutoApproveHours().then((hours) {
      if (mounted) setState(() => _autoApproveHours = hours);
    });

    if (widget.allSubmissions != null && widget.allSubmissions!.isNotEmpty) {
      _submissions = List.from(widget.allSubmissions!);
      for (final s in _submissions) {
        _statuses[s.id] = s.status;
      }
    } else if (widget.initialSubmission != null) {
      _submissions = [widget.initialSubmission!];
      _statuses[widget.initialSubmission!.id] = widget.initialSubmission!.status;
      _loadPendingQueue();
    } else {
      _loadSubmissionDetail();
      _loadPendingQueue();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _pendingCount {
    return _submissions.where((s) {
      final st = (_statuses[s.id] ?? s.status).toUpperCase();
      return st == 'PENDING' || st == 'SUBMITTED' || st == 'UNDER_REVIEW';
    }).length;
  }

  Future<void> _loadSubmissionDetail() async {
    if (_submissions.isEmpty) {
      setState(() => _isLoading = true);
    }
    final result = await _reviewRepo.getReviewDetail(widget.submissionId);
    if (!mounted) return;

    result.fold(
      (failure) {
        if (_submissions.isEmpty) {
          setState(() => _isLoading = false);
        }
      },
      (detail) {
        setState(() {
          _isLoading = false;
          _statuses[detail.id] = detail.status;
          final existingIdx = _submissions.indexWhere((s) => s.id == detail.id);
          if (existingIdx >= 0) {
            _submissions[existingIdx] = detail;
          } else {
            _submissions.insert(0, detail);
          }
        });
      },
    );
  }

  Future<void> _loadPendingQueue() async {
    final result = await _reviewRepo.getPendingReviews();
    if (!mounted) return;

    result.fold(
      (_) {},
      (pendingList) {
        if (pendingList.isEmpty) return;
        setState(() {
          for (final item in pendingList) {
            if (!_submissions.any((s) => s.id == item.id)) {
              _submissions.add(item);
            }
            _statuses.putIfAbsent(item.id, () => item.status);
          }
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

  /// Single Task Proof Approval with Reel Auto-advance
  Future<void> _approveCurrentProof(ReviewSubmissionModel item) async {
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    final result = await _reviewRepo.approveTaskProof(item.id);
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
            _statuses[item.id] = 'APPROVED';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Task approved! Worker ${item.workerName} paid.'),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
              duration: const Duration(seconds: 1),
            ),
          );

          // Auto-advance to next proof if available!
          if (_currentIndex < _submissions.length - 1) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _pageController.hasClients) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                );
              }
            });
          }
        }
      },
    );
  }

  /// Single Task Proof Rejection with Feedback
  void _rejectCurrentProof(ReviewSubmissionModel item) {
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
              'Please provide clear feedback for worker ${item.workerName}:',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E1B4B)),
              decoration: InputDecoration(
                hintText: 'e.g. Screenshot blurry / required action not visible in proof',
                hintStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFFAF5FF),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
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
              style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontWeight: FontWeight.w600),
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
                item.id,
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
                      _statuses[item.id] = 'REJECTED';
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task proof rejected with feedback.'),
                        backgroundColor: Color(0xFFDC2626),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Auto-advance to next proof
                    if (_currentIndex < _submissions.length - 1) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted && _pageController.hasClients) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      });
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Bulk Approve All Submissions with Modal Confirmation
  void _confirmApproveAll() {
    final count = _pendingCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All submissions have already been reviewed!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.done_all_rounded, color: Color(0xFF059669), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Approve All?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: const Color(0xFF065F46),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve all $count pending submissions? All workers will be credited immediately.',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF4B5563), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isProcessing = true);

              final pendingIds = _submissions.where((s) {
                final st = (_statuses[s.id] ?? s.status).toUpperCase();
                return st == 'PENDING' || st == 'SUBMITTED' || st == 'UNDER_REVIEW';
              }).map((s) => s.id).toList();

              final result = await _reviewRepo.approveAllTaskProofs(
                orderId: widget.campaignId,
                submissionIds: pendingIds,
              );

              if (!mounted) return;

              result.fold(
                (failure) {
                  setState(() => _isProcessing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to bulk approve: ${failure.message}'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                },
                (data) {
                  final approvedCount = data['approvedCount'] ?? count;
                  setState(() {
                    _isProcessing = false;
                    for (final id in pendingIds) {
                      _statuses[id] = 'APPROVED';
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully approved all $approvedCount submissions in bulk!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Approve All ($count)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _submissions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF090D16),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Loading Proofs...',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    final pendingCount = _pendingCount;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // ── 1. The Reels Vertical PageView ──────────────────────────────
          if (_submissions.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_outlined, size: 48, color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Proofs to Review',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              itemCount: _submissions.length,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, index) {
                return _buildReelSlide(_submissions[index], index);
              },
            ),

          // ── 2. Top Persistent Header Bar with "Approve All" Button ──────
          SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),

                  // Reels Counter Badge (e.g. 3 of 15)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.view_carousel_rounded, color: Color(0xFFE9D5FF), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _submissions.isNotEmpty
                              ? '${_currentIndex + 1} / ${_submissions.length}'
                              : '1 / 1',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Top "Approve All" Review Button
                  if (pendingCount > 0)
                    InkWell(
                      onTap: _isProcessing ? null : _confirmApproveAll,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_all_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              'Approve All ($pendingCount)',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.45)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'All Done ✓',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single Reel Slide Layout
  Widget _buildReelSlide(ReviewSubmissionModel item, int index) {
    final status = (_statuses[item.id] ?? item.status).toUpperCase();
    final isApproved = status == 'APPROVED';
    final isRejected = status == 'REJECTED';
    final isPending = !isApproved && !isRejected;

    final submittedDateStr =
        '${item.submittedAt.day}/${item.submittedAt.month}/${item.submittedAt.year} ${item.submittedAt.hour.toString().padLeft(2, '0')}:${item.submittedAt.minute.toString().padLeft(2, '0')}';
    final shortWorkerId = item.workerId.length > 8 ? item.workerId.substring(0, 8) : item.workerId;
    final shortTaskId = item.taskId.length > 8 ? item.taskId.substring(0, 8).toUpperCase() : item.taskId.toUpperCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Proof Screenshot Area (Center & Zoomable) ────────────────────
        GestureDetector(
          onTap: item.proofScreenshotUrl.isNotEmpty && item.proofScreenshotUrl.startsWith('http')
              ? () => _showFullScreenImage(item.proofScreenshotUrl)
              : null,
          child: Container(
            color: const Color(0xFF090D16),
            child: item.proofScreenshotUrl.isNotEmpty && item.proofScreenshotUrl.startsWith('http')
                ? InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: Center(
                      child: Image.network(
                        item.proofScreenshotUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
                        },
                        errorBuilder: (c, err, st) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFFA78BFA)),
                              const SizedBox(height: 8),
                              Text('Failed to load image', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.image_not_supported_rounded, size: 44, color: Colors.white54),
                        ),
                        const SizedBox(height: 12),
                        Text('No Screenshot Attached', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
          ),
        ),

        // ── 2. Tap to Zoom Floating Badge ──────────────────────────────────
        if (item.proofScreenshotUrl.isNotEmpty && item.proofScreenshotUrl.startsWith('http'))
          Positioned(
            top: 86,
            right: 16,
            child: GestureDetector(
              onTap: () => _showFullScreenImage(item.proofScreenshotUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Zoom', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),

        // ── 3. Bottom Gradient Scrim & Info/Action Card ────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.96),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task Title & Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.taskTitle,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (shortTaskId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Task #$shortTaskId',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFA78BFA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? const Color(0xFF059669).withValues(alpha: 0.25)
                            : isRejected
                                ? const Color(0xFFDC2626).withValues(alpha: 0.25)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isApproved
                              ? const Color(0xFF34D399)
                              : isRejected
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFFBBF24),
                          width: 1,
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
                                ? const Color(0xFF34D399)
                                : isRejected
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: GoogleFonts.outfit(
                              color: isApproved
                                  ? const Color(0xFF34D399)
                                  : isRejected
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFFBBF24),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Worker Profile Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.workerName.isNotEmpty ? item.workerName[0].toUpperCase() : 'W',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.workerName,
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Worker ID: $shortWorkerId • $submittedDateStr',
                              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Proof Text / Comment pasted by worker
                if (item.proofText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, color: Color(0xFFA78BFA), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.proofText,
                            style: GoogleFonts.outfit(color: const Color(0xFFE9D5FF), fontSize: 12, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Auto-approve notice banner
                if (isPending) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If you do not review this proof, it will auto-approve within ${_autoApproveHours.toInt()} hours automatically.',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFEF3C7),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons Row (Approve / Reject)
                if (isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : () => _rejectCurrentProof(item),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text('Reject', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            backgroundColor: const Color(0xFF7F1D1D).withValues(alpha: 0.25),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _approveCurrentProof(item),
                          icon: _isProcessing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_isProcessing ? 'Processing...' : 'Approve Task', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFF059669).withValues(alpha: 0.2)
                          : const Color(0xFFDC2626).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isApproved ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isApproved ? 'Approved • Worker Credited' : 'Rejected with Feedback',
                          style: GoogleFonts.outfit(
                            color: isApproved ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Next Swipe Hint
                if (index < _submissions.length - 1) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54, size: 16),
                        Text(
                          'Swipe up for next proof (${index + 2}/${_submissions.length})',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
