import 'package:flutter/material.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/repositories/campaign_repository.dart';
import '../../../../reviews/presentation/pages/review_detail_page.dart';

class TasksTab extends StatefulWidget {
  final String campaignId;

  const TasksTab({super.key, required this.campaignId});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = getIt<CampaignRepository>();
    final result = await repo.getCampaignTasks(widget.campaignId);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (tasks) {
        setState(() {
          _isLoading = false;
          _allTasks = tasks;
        });
      },
    );
  }

  bool _matchesStatus(String status, String target) {
    final s = status.toLowerCase().trim();
    switch (target) {
      case 'pending':
        return s == 'pending' || s == 'available' || s == 'created' || s == 'active' || s == 'draft';
      case 'working':
        return s == 'assigned' || s == 'in_progress' || s == 'working' || s == 'started' || s == 'accepted';
      case 'submitted':
        return s == 'submitted' || s == 'under_review' || s == 'review';
      case 'approved':
        return s == 'completed' || s == 'approved' || s == 'done';
      case 'rejected':
        return s == 'rejected';
      default:
        return true;
    }
  }

  List<dynamic> _filterTasks(String target) {
    if (target == 'all') return _allTasks;
    return _allTasks.where((t) {
      final status = (t['status'] ?? '').toString();
      return _matchesStatus(status, target);
    }).toList();
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
            Text('Loading campaign tasks...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                onPressed: _fetchTasks,
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

    final all = _filterTasks('all');
    final pending = _filterTasks('pending');
    final working = _filterTasks('working');
    final submitted = _filterTasks('submitted');
    final approved = _filterTasks('approved');
    final rejected = _filterTasks('rejected');

    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              tabs: [
                Tab(text: 'All (${all.length})'),
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'Working (${working.length})'),
                Tab(text: 'Submitted (${submitted.length})'),
                Tab(text: 'Approved (${approved.length})'),
                Tab(text: 'Rejected (${rejected.length})'),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: TabBarView(
              children: [
                _buildTaskList(all, 'No tasks created yet.'),
                _buildTaskList(pending, 'No pending tasks. All claimed by workers.'),
                _buildTaskList(working, 'No workers currently executing tasks.'),
                _buildTaskList(submitted, 'No proofs submitted awaiting review.'),
                _buildTaskList(approved, 'No approved tasks yet.'),
                _buildTaskList(rejected, 'No rejected tasks.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks, String emptyMessage) {
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_outlined, size: 36, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pull down to refresh live tasks status',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final t = tasks[index] as Map<String, dynamic>;
          return _TaskCard(task: t, onRefresh: _fetchTasks);
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onRefresh;

  const _TaskCard({required this.task, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final id = (task['id'] ?? '').toString();
    final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
    final status = (task['status'] ?? 'PENDING').toString().toUpperCase();
    final worker = (task['assignedTo'] ?? task['workerId'] ?? 'Unassigned').toString();
    final reward = task['rewardAmount'] != null ? '₹${task['rewardAmount']}' : '';
    final bool isReviewable = status == 'SUBMITTED' || status == 'UNDER_REVIEW';

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (status) {
      case 'COMPLETED':
      case 'APPROVED':
        statusBgColor = const Color(0xFFECFDF5);
        statusTextColor = const Color(0xFF10B981);
        statusLabel = 'Completed';
        break;
      case 'ASSIGNED':
      case 'IN_PROGRESS':
      case 'WORKING':
        statusBgColor = const Color(0xFFEFF6FF);
        statusTextColor = const Color(0xFF2563EB);
        statusLabel = 'In Progress';
        break;
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        statusBgColor = const Color(0xFFFFFBEB);
        statusTextColor = const Color(0xFFD97706);
        statusLabel = 'Under Review';
        break;
      case 'REJECTED':
        statusBgColor = const Color(0xFFFEF2F2);
        statusTextColor = const Color(0xFFEF4444);
        statusLabel = 'Rejected';
        break;
      default:
        statusBgColor = const Color(0xFFF1F5F9);
        statusTextColor = const Color(0xFF64748B);
        statusLabel = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isReviewable ? const Color(0xFFF59E0B).withOpacity(0.5) : const Color(0xFFE2E8F0),
          width: isReviewable ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isReviewable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewDetailPage(submissionId: id),
                    ),
                  ).then((_) => onRefresh?.call());
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 2),
                        Text(
                          'TASK-$shortId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isReviewable) ...[
                          const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 2),
                          const Text(
                            'Review Proof',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          worker == 'Unassigned' ? 'Worker: Unassigned' : 'Worker: ${worker.length > 10 ? worker.substring(0, 10) + '...' : worker}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    if (reward.isNotEmpty)
                      Text(
                        'Reward: $reward',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
