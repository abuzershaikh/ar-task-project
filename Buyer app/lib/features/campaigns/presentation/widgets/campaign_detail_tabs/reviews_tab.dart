import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/repositories/campaign_repository.dart';
import '../../../../reviews/data/repositories/review_repository.dart';
import '../../../../reviews/presentation/pages/review_detail_page.dart';
import '../../../../reviews/data/models/review_submission_model.dart';

class ReviewsTab extends StatefulWidget {
  final String campaignId;

  const ReviewsTab({super.key, required this.campaignId});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  bool _isLoading = true;
  bool _isAutoApprove = false;
  bool _isActionInProgress = false;
  String? _errorMessage;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _fetchAutoApproveStatus();
  }

  Future<void> _fetchAutoApproveStatus() async {
    try {
      final reviewRepo = getIt<ReviewRepository>();
      final res = await reviewRepo.getAutoApproveStatus(orderId: widget.campaignId);
      res.fold((_) {}, (val) {
        if (mounted) setState(() => _isAutoApprove = val);
      });
    } catch (_) {}
  }

  Future<void> _toggleAutoApprove(bool val) async {
    setState(() => _isAutoApprove = val);
    try {
      final reviewRepo = getIt<ReviewRepository>();
      final res = await reviewRepo.toggleAutoApprove(autoApprove: val, orderId: widget.campaignId);
      res.fold(
        (fail) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(fail.message), backgroundColor: Colors.red),
            );
            _fetchAutoApproveStatus();
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(val
                    ? 'Auto-approval enabled for this campaign!'
                    : 'Auto-approval disabled. Submissions will require manual review.'),
                backgroundColor: const Color(0xFF059669),
              ),
            );
            _fetchReviews();
          }
        },
      );
    } catch (e) {
      if (mounted) _fetchAutoApproveStatus();
    }
  }

  Future<void> _approveAllSubmissions() async {
    setState(() => _isActionInProgress = true);
    try {
      final reviewRepo = getIt<ReviewRepository>();
      final res = await reviewRepo.approveAllTaskProofs(orderId: widget.campaignId);
      res.fold(
        (fail) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(fail.message), backgroundColor: Colors.red),
            );
          }
        },
        (data) {
          final count = data['approvedCount'] ?? 0;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully approved $count submissions!'),
                backgroundColor: const Color(0xFF059669),
              ),
            );
          }
          _fetchReviews();
        },
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _confirmApproveAll() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve all ${_reviews.length} pending submissions? Worker rewards will be credited immediately.',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _approveAllSubmissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Approve All (${_reviews.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = getIt<CampaignRepository>();
    final result = await repo.getCampaignReviews(widget.campaignId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (reviews) {
        setState(() {
          _isLoading = false;
          _reviews = reviews;
        });
      },
    );
  }

  Widget _buildAutoApproveCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isAutoApprove ? const Color(0xFFFAF5FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAutoApprove ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isAutoApprove ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Auto-Approve Proofs',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isAutoApprove ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isAutoApprove ? 'ACTIVE' : 'OFF',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isAutoApprove ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isAutoApprove
                      ? 'Valid worker proofs are automatically approved and credited'
                      : 'Enable to automatically approve proofs for this campaign',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isAutoApprove,
            activeColor: const Color(0xFF7C3AED),
            onChanged: _toggleAutoApprove,
          ),
        ],
      ),
    );
  }

  Widget _buildApproveAllBar() {
    if (_reviews.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.playlist_add_check_circle_rounded, color: Color(0xFF059669), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending: ${_reviews.length} Submissions',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF065F46)),
                ),
                const Text(
                  'Accept all proofs at once',
                  style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isActionInProgress ? null : _confirmApproveAll,
            icon: _isActionInProgress
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Approve All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('Loading pending reviews...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchReviews,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchReviews,
        child: ListView(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildAutoApproveCard(),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review_outlined, size: 36, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Submissions Pending Review',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When workers submit task proofs and screenshots, they will appear here for your verification and approval.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _fetchReviews,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Reviews'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

    return RefreshIndicator(
      onRefresh: _fetchReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _reviews.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return _buildAutoApproveCard();
          if (index == 1) return _buildApproveAllBar();

          final review = _reviews[index - 2] as Map<String, dynamic>;
          final id = (review['id'] ?? '').toString();
          final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
          final worker = (review['workerId'] ?? 'Worker').toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task #$shortId',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Worker: ${worker.length > 12 ? worker.substring(0, 12) + '...' : worker}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Proof submitted • Awaiting review',
                        style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final submissionModel = ReviewSubmissionModel.fromJson(Map<String, dynamic>.from(review));

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewDetailPage(
                          submissionId: id,
                          initialSubmission: submissionModel,
                        ),
                      ),
                    ).then((_) => _fetchReviews());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Review'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
