import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/campaign_detail_bloc.dart';
import '../bloc/campaign_detail_event.dart';
import '../bloc/campaign_detail_state.dart';
import '../widgets/campaign_detail_tabs/overview_tab.dart';
import '../widgets/campaign_detail_tabs/tasks_tab.dart';
import '../widgets/campaign_detail_tabs/reviews_tab.dart';
import '../widgets/campaign_detail_tabs/activity_tab.dart';
import '../widgets/campaign_detail_tabs/analytics_tab.dart';

class CampaignDetailPage extends StatelessWidget {
  final String campaignId;

  const CampaignDetailPage({
    super.key,
    required this.campaignId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CampaignDetailBloc>()..add(GetCampaignDetailEvent(campaignId)),
      child: _CampaignDetailView(campaignId: campaignId),
    );
  }
}

class _CampaignDetailView extends StatefulWidget {
  final String campaignId;

  const _CampaignDetailView({required this.campaignId});

  @override
  State<_CampaignDetailView> createState() => _CampaignDetailViewState();
}

class _CampaignDetailViewState extends State<_CampaignDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CampaignDetailBloc, CampaignDetailState>(
        listener: (context, state) {
          if (state is CampaignDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CampaignDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CampaignDetailLoaded) {
            final campaign = state.campaign;

            return CustomScrollView(
              slivers: [
                // App Bar with Campaign Info
                SliverAppBar(
                  expandedHeight: 110,
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xFF0F172A),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      onSelected: (value) => _handleMenuAction(value, campaign.id),
                      itemBuilder: (context) => [
                        if (campaign.isActive)
                          const PopupMenuItem(
                            value: 'pause',
                            child: Row(
                              children: [
                                Icon(Icons.pause_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Pause Campaign', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        if (campaign.isPaused)
                          const PopupMenuItem(
                            value: 'resume',
                            child: Row(
                              children: [
                                Icon(Icons.play_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Resume Campaign', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'invoice',
                          child: Row(
                            children: [
                              Icon(Icons.receipt_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('View Invoice', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Report Issue', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        if (!campaign.isCompleted && !campaign.isCancelled)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Cancel Campaign', style: TextStyle(color: Colors.red, fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              campaign.id,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(status: campaign.status),
                          ],
                        ),
                      ],
                    ),
                    titlePadding: const EdgeInsets.only(left: 48, bottom: 12, right: 48),
                  ),
                ),

                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Tasks'),
                        Tab(text: 'Reviews'),
                        Tab(text: 'Activity'),
                        Tab(text: 'Analytics'),
                      ],
                    ),
                  ),
                ),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      OverviewTab(campaign: campaign),
                      TasksTab(campaignId: campaign.id),
                      ReviewsTab(campaignId: campaign.id),
                      ActivityTab(campaignId: campaign.id),
                      AnalyticsTab(campaign: campaign),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action, String campaignId) {
    switch (action) {
      case 'pause':
        _showConfirmDialog(
          'Pause Campaign',
          'Are you sure you want to pause this campaign?',
          () => context.read<CampaignDetailBloc>().add(
                PauseCampaignEvent(campaignId),
              ),
        );
        break;
      case 'resume':
        context.read<CampaignDetailBloc>().add(ResumeCampaignEvent(campaignId));
        break;
      case 'cancel':
        _showConfirmDialog(
          'Cancel Campaign',
          'Are you sure you want to cancel this campaign? This action cannot be undone.',
          () => context.read<CampaignDetailBloc>().add(
                CancelCampaignEvent(campaignId),
              ),
          isDestructive: true,
        );
        break;
      case 'invoice':
        break;
      case 'report':
        break;
    }
  }

  void _showConfirmDialog(
    String title,
    String message,
    VoidCallback onConfirm, {
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : null,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String emoji;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        emoji = '🟢';
        break;
      case 'paused':
        color = Colors.orange;
        emoji = '🟡';
        break;
      case 'completed':
        color = Colors.blue;
        emoji = '✓';
        break;
      case 'cancelled':
        color = Colors.red;
        emoji = '🔴';
        break;
      default:
        color = Colors.grey;
        emoji = '⚪';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
