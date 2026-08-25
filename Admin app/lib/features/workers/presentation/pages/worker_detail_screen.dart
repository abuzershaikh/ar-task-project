import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/workers_bloc.dart';
import '../widgets/worker_detail_tabs/overview_tab.dart';
import '../widgets/worker_detail_tabs/tasks_tab.dart';
import '../widgets/worker_detail_tabs/kyc_tab.dart';
import '../widgets/worker_detail_tabs/earnings_tab.dart';
import '../widgets/worker_detail_tabs/ratings_tab.dart';
import '../widgets/worker_detail_tabs/quality_score_tab.dart';
import '../widgets/worker_detail_tabs/risk_tab.dart';
import '../widgets/worker_detail_tabs/activity_tab.dart';

class WorkerDetailScreen extends StatefulWidget {
  final String workerId;

  const WorkerDetailScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    context.read<WorkersBloc>().add(LoadWorkerDetailEvent(widget.workerId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.workerId.length > 14
        ? '#${widget.workerId.substring(0, 8)}...${widget.workerId.substring(widget.workerId.length - 4)}'
        : widget.workerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        titleSpacing: 14,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: BlocBuilder<WorkersBloc, WorkersState>(
          builder: (context, state) {
            String name = 'Worker Intelligence Profile';
            String email = shortId;
            if (state is WorkerDetailLoaded &&
                (state.worker.id == widget.workerId || state.worker.userId == widget.workerId)) {
              name = state.worker.name.isNotEmpty ? state.worker.name : 'Worker Profile';
              email = state.worker.email.isNotEmpty
                  ? state.worker.email
                  : (state.worker.phone.isNotEmpty ? state.worker.phone : shortId);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text(
                  email,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFE0F2FE), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              _handleAction(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text('Suspend Worker'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text('Ban Worker'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_status',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Color(0xFF0284C7), size: 20),
                    SizedBox(width: 8),
                    Text('Change Status'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          labelPadding: const EdgeInsets.symmetric(horizontal: 14.0),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tasks'),
            Tab(text: 'KYC'),
            Tab(text: 'Earnings'),
            Tab(text: 'Ratings'),
            Tab(text: 'Quality'),
            Tab(text: 'Risk'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: BlocBuilder<WorkersBloc, WorkersState>(
        builder: (context, state) {
          if (state is WorkersLoading || state is WorkerDetailLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
          }
          if (state is WorkersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Color(0xFFDC2626))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                    onPressed: () {
                      context.read<WorkersBloc>().add(LoadWorkerDetailEvent(widget.workerId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is WorkerDetailLoaded) {
            final detailState = state as WorkerDetailLoaded;
            if (detailState.worker.id != widget.workerId && detailState.worker.userId != widget.workerId) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
            }
            return TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(worker: detailState.worker, tasks: detailState.tasks, earnings: detailState.earnings),
                TasksTab(tasks: detailState.tasks),
                KycTab(worker: detailState.worker),
                EarningsTab(worker: detailState.worker, earnings: detailState.earnings),
                RatingsTab(worker: detailState.worker, ratings: detailState.ratings),
                QualityScoreTab(worker: detailState.worker, scoreHistory: detailState.scoreHistory),
                RiskTab(worker: detailState.worker, risk: detailState.risk),
                ActivityTab(activity: detailState.activity),
              ],
            );
          }
          
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
        },
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'suspend':
        _showConfirmDialog('Suspend Worker', 'Are you sure you want to suspend this worker?');
        break;
      case 'ban':
        _showConfirmDialog('Ban Worker', 'Are you sure you want to ban this worker? This action requires SUPER_ADMIN approval.');
        break;
      case 'change_status':
        _showStatusChangeDialog();
        break;
    }
  }

  void _showConfirmDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Reason (Required)',
                hintText: 'Enter reason for this action',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStatus = title.toLowerCase().contains('ban') ? 'BANNED' : 'SUSPENDED';
              context.read<WorkersBloc>().add(
                UpdateWorkerStatusEvent(workerId: widget.workerId, status: newStatus),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Worker Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Active'),
                value: 'ACTIVE',
                groupValue: _selectedStatus,
                onChanged: (val) {
                  if (val != null) setDialogState(() => _selectedStatus = val);
                },
              ),
              RadioListTile<String>(
                title: const Text('Inactive'),
                value: 'INACTIVE',
                groupValue: _selectedStatus,
                onChanged: (val) {
                  if (val != null) setDialogState(() => _selectedStatus = val);
                },
              ),
              RadioListTile<String>(
                title: const Text('Suspended'),
                value: 'SUSPENDED',
                groupValue: _selectedStatus,
                onChanged: (val) {
                  if (val != null) setDialogState(() => _selectedStatus = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<WorkersBloc>().add(
                  UpdateWorkerStatusEvent(workerId: widget.workerId, status: _selectedStatus),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
