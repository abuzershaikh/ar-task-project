import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../../../wallet/presentation/widgets/balance_card.dart';
import '../../../wallet/presentation/pages/wallet_screen.dart';
import '../../../campaigns/presentation/pages/campaign_detail_page.dart';
import '../../../reviews/presentation/pages/reviews_page.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/action_required_card.dart';
import '../widgets/campaign_overview_card.dart';
import '../widgets/spending_card.dart';
import '../widgets/active_campaign_card.dart';
import '../widgets/quick_actions_grid.dart';

class EnhancedHomePage extends StatefulWidget {
  const EnhancedHomePage({super.key});

  @override
  State<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends State<EnhancedHomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<WalletBloc>().add(const GetBalanceEvent());
    context.read<HomeBloc>().add(const LoadHomeDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 80,
              floating: true,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Text(
                      'Marketing Pro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
              ],
            ),

            // Wallet Balance Card
            SliverToBoxAdapter(
              child: BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  if (state is WalletLoaded) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: BalanceCard(
                        balance: state.balance,
                        onAddBalance: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Home Content
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is HomeLoaded) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campaign Overview
                          CampaignOverviewCard(
                            activeCampaigns: state.activeCampaigns,
                            completedCampaigns: state.completedCampaigns,
                            totalTasks: state.totalTasks,
                            completedTasks: state.completedTasks,
                            completionPercentage: state.completionPercentage,
                          ),
                          const SizedBox(height: 16),

                          // Spending Card
                          SpendingCard(
                            totalSpent: state.totalSpent,
                            thisMonthSpent: state.thisMonthSpent,
                            monthlyGrowth: state.monthlyGrowth,
                            onViewPayments: () {
                              // Navigate to payments
                            },
                          ),
                          const SizedBox(height: 16),

                          // Action Required Card
                          ActionRequiredCard(
                            pendingReviews: state.pendingReviews,
                            onReviewNow: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReviewsPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Active Campaigns
                          if (state.recentCampaigns.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Active Campaigns',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to campaigns
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...state.recentCampaigns.take(3).map(
                                  (campaign) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ActiveCampaignCard(
                                      campaign: campaign,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CampaignDetailPage(
                                              campaignId: campaign.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 24),
                          ],

                          // Quick Actions
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          QuickActionsGrid(
                            onCreateCampaign: () {
                              // Navigate to create campaign
                            },
                            onServices: () {
                              // Navigate to services
                            },
                            onReviews: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReviewsPage(),
                                ),
                              );
                            },
                            onPayments: () {
                              // Navigate to payments
                            },
                            onAnalytics: () {
                              // Navigate to analytics
                            },
                            onInvoices: () {
                              // Navigate to invoices
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                }

                return const SliverFillRemaining(
                  child: Center(child: Text('Something went wrong')),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create campaign wizard
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Campaign'),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }
}
