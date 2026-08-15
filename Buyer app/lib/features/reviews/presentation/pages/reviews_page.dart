import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/reviews_bloc.dart';
import '../../data/models/review_submission_model.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReviewsBloc>()..add(LoadPendingReviewsEvent()),
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
        appBar: AppBar(
          title: const Text('Task Reviews Queue'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<ReviewsBloc>().add(LoadPendingReviewsEvent());
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
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
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
            } else if (state is ReviewsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is ReviewsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ReviewsLoaded) {
              return TabBarView(
                children: [
                  _buildReviewList(context, state.submissions, 'pending'),
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
          const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildReviewList(BuildContext context, List<ReviewSubmissionModel> submissions, String type) {
    if (submissions.isEmpty) {
      return _buildEmptyState(context, 'No submissions found');
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ReviewsBloc>().add(LoadPendingReviewsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final item = submissions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.taskTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.status,
                        style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Worker: ${item.workerName}'),
                const SizedBox(height: 4),
                if (item.proofText.isNotEmpty)
                  Text('Proof Text: ${item.proofText}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
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
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<ReviewsBloc>().add(ApproveReviewEvent(item.id));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
