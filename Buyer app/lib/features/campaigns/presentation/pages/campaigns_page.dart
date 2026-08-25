import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../bloc/campaigns_list_bloc.dart';
import '../../domain/entities/campaign_detail.dart';

class CampaignsPage extends StatelessWidget {
  const CampaignsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CampaignsListBloc>()..add(const LoadCampaignsListEvent()),
      child: const _CampaignsView(),
    );
  }
}

class _CampaignsView extends StatefulWidget {
  const _CampaignsView();

  @override
  State<_CampaignsView> createState() => _CampaignsViewState();
}

class _CampaignsViewState extends State<_CampaignsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['all', 'active', 'in_progress', 'completed', 'paused', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _statuses[_tabController.index];
    context.read<CampaignsListBloc>().add(LoadCampaignsListEvent(status: status));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final status = _statuses[_tabController.index];
              context.read<CampaignsListBloc>().add(RefreshCampaignsListEvent(status: status));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Paused'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: BlocBuilder<CampaignsListBloc, CampaignsListState>(
        builder: (context, state) {
          if (state is CampaignsListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CampaignsListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final status = _statuses[_tabController.index];
                      context.read<CampaignsListBloc>().add(LoadCampaignsListEvent(status: status));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CampaignsListLoaded) {
            if (state.campaigns.isEmpty) {
              return _buildEmptyState(_statuses[_tabController.index]);
            }

            return RefreshIndicator(
              onRefresh: () async {
                final status = _statuses[_tabController.index];
                context.read<CampaignsListBloc>().add(RefreshCampaignsListEvent(status: status));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = state.campaigns[index];
                  return _buildCampaignCard(context, campaign);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.services);
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Campaign'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, CampaignDetail campaign) {
    Color statusColor;
    Color statusBg;
    switch (campaign.status.toLowerCase()) {
      case 'active':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        break;
      case 'paused':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFFFBEB);
        break;
      case 'completed':
        statusColor = const Color(0xFF2563EB);
        statusBg = const Color(0xFFEFF6FF);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEF2F2);
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFFF8FAFC);
    }

    final double progress = campaign.totalTasks > 0 ? (campaign.completedTasks / campaign.totalTasks).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.campaignDetail,
              arguments: campaign.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Title + Status Chip
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            campaign.serviceName.isNotEmpty ? campaign.serviceName : 'Custom Service',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            campaign.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Mini Analytics Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                    ),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Compact Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tasks Count & %
                    Row(
                      children: [
                        const Icon(Icons.task_alt_rounded, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '${campaign.completedTasks}/${campaign.totalTasks}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          ' ($percent%)',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    // Budget Amount
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '₹${campaign.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    // Analytics Arrow
                    const Row(
                      children: [
                        Text('Analytics', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF2563EB)),
                      ],
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

  Widget _buildEmptyState(String status) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.replaceAll('_', ' ')} campaigns found',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.services);
              },
              child: const Text('Create Your First Campaign'),
            ),
          ],
        ),
      ),
    );
  }
}
