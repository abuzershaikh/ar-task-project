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
    switch (campaign.status.toLowerCase()) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'paused':
        statusColor = AppColors.warning;
        break;
      case 'completed':
        statusColor = AppColors.info;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      campaign.name,
                      style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      campaign.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Service: ${campaign.serviceName}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: campaign.totalTasks > 0 ? (campaign.completedTasks / campaign.totalTasks) : 0,
                backgroundColor: AppColors.gray200,
                color: AppColors.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${campaign.completedTasks} / ${campaign.totalTasks} completed',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹${campaign.totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
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
