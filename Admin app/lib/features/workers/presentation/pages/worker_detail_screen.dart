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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Worker Details'),
            Text(
              widget.workerId,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              _handleAction(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text('Suspend Worker'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ban',
                child: Row(
                  children: [
                    Icon(Icons.block, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Ban Worker'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'change_status',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
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
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
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
          if (state is WorkersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WorkersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WorkersBloc>().add(LoadWorkerDetailEvent(widget.workerId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is WorkerDetailLoaded && state.worker.id != widget.workerId) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(workerId: widget.workerId),
              TasksTab(workerId: widget.workerId),
              KycTab(workerId: widget.workerId),
              EarningsTab(workerId: widget.workerId),
              RatingsTab(workerId: widget.workerId),
              QualityScoreTab(workerId: widget.workerId),
              RiskTab(workerId: widget.workerId),
              ActivityTab(workerId: widget.workerId),
            ],
          );
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
