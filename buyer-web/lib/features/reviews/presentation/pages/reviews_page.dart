import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection.dart';
import '../bloc/reviews_bloc.dart';
import '../../data/models/review_submission_model.dart';
import 'review_detail_page.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReviewsBloc>()..add(const LoadPendingReviewsEvent()),
      child: const _ReviewsView(),
    );
  }
}

class _ReviewsView extends StatelessWidget {
  const _ReviewsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF5FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF6D28D9)),
          title: Text(
            'Task Reviews Queue',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E1B4B),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6D28D9)),
              onPressed: () {
                context.read<ReviewsBloc>().add(const LoadPendingReviewsEvent());
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF7C3AED),
            indicatorWeight: 3,
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: const Color(0xFF6B7280),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Pending Queue'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: BlocConsumer<ReviewsBloc, ReviewsState>(
          listener: (context, state) {
            if (state is ReviewActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            } else if (state is ReviewsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ReviewsLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
            }

            if (state is ReviewsLoaded) {
              return TabBarView(
                children: [
                  _buildReviewList(
                    context,
                    state.submissions,
                    'pending',
                    isAutoApprove: state.isAutoApprove,
                  ),
                  _buildReviewList(context, [], 'approved'),
                  _buildReviewList(context, [], 'rejected'),
                ],
              );
            }

            return TabBarView(
              children: [
                _buildEmptyState(context, 'No pending submissions to review'),
                _buildEmptyState(context, 'No approved reviews'),
                _buildEmptyState(context, 'No rejected reviews'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(
              color: const Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoApproveToggleCard(BuildContext context, bool isAutoApprove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAutoApprove
              ? [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)]
              : [Colors.white, const Color(0xFFF9FAFB)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAutoApprove ? const Color(0xFFDDD6FE) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isAutoApprove
                ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAutoApprove ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
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
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAutoApprove ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isAutoApprove ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        isAutoApprove ? 'ACTIVE' : 'OFF',
                        style: GoogleFonts.outfit(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isAutoApprove ? const Color(0xFF059669) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isAutoApprove
                      ? 'Worker proofs are approved and credited automatically'
                      : 'Turn on to automatically approve all incoming worker proofs',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: isAutoApprove,
            activeColor: const Color(0xFF7C3AED),
            onChanged: (val) {
              context.read<ReviewsBloc>().add(ToggleAutoApproveEvent(autoApprove: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApproveAllBar(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
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
                  'Pending Review: $count Tasks',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Accept all tasks in a single click',
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF047857)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmApproveAll(context, count),
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Approve All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmApproveAll(BuildContext context, int count) {
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
          'Are you sure you want to approve all $count pending submissions? Worker rewards will be credited immediately.',
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
              context.read<ReviewsBloc>().add(const ApproveAllReviewsEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text('Approve All ($count)', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(
    BuildContext context,
    List<ReviewSubmissionModel> submissions,
    String type, {
    bool isAutoApprove = false,
  }) {
    final isPendingTab = type == 'pending';

    if (submissions.isEmpty) {
      if (isPendingTab) {
        return RefreshIndicator(
          color: const Color(0xFF7C3AED),
          onRefresh: () async {
            context.read<ReviewsBloc>().add(const LoadPendingReviewsEvent());
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildAutoApproveToggleCard(context, isAutoApprove),
              const SizedBox(height: 32),
              _buildEmptyState(context, 'No pending submissions to review'),
            ],
          ),
        );
      }
      return _buildEmptyState(context, 'No submissions found');
    }

    return RefreshIndicator(
      color: const Color(0xFF7C3AED),
      onRefresh: () async {
        context.read<ReviewsBloc>().add(const LoadPendingReviewsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length + (isPendingTab ? 2 : 0),
        itemBuilder: (context, index) {
          if (isPendingTab && index == 0) {
            return _buildAutoApproveToggleCard(context, isAutoApprove);
          }
          if (isPendingTab && index == 1) {
            return _buildApproveAllBar(context, submissions.length);
          }

          final itemIndex = isPendingTab ? index - 2 : index;
          final item = submissions[itemIndex];
          final isPending = item.status.toUpperCase() == 'PENDING' || item.status.toUpperCase() == 'SUBMITTED';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewDetailPage(
                        submissionId: item.id,
                        initialSubmission: item,
                      ),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<ReviewsBloc>().add(const LoadPendingReviewsEvent());
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.taskTitle,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: const Color(0xFF1E1B4B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDD6FE)),
                            ),
                            child: Text(
                              item.status,
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Text(
                            'Worker: ${item.workerName}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (item.proofScreenshotUrl.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.image_outlined, size: 14, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            Text(
                              'Screenshot Proof Attached',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF7C3AED),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.proofText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEDE9FE)),
                          ),
                          child: Text(
                            item.proofText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: const Color(0xFF4B5563), fontSize: 11.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (isPending)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  context.read<ReviewsBloc>().add(RejectReviewEvent(
                                    submissionId: item.id,
                                    reasonCode: 'INVALID_PROOF',
                                    note: 'Proof submitted is not valid',
                                  ));
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  side: const BorderSide(color: Color(0xFFFECACA)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text(
                                  'Reject',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<ReviewsBloc>().add(ApproveReviewEvent(item.id));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: Text(
                                  'Approve',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
