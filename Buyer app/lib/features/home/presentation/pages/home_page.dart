import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/campaign_overview_card.dart';
import '../widgets/recent_campaign_item.dart';
import '../widgets/info_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<DashboardBloc>().add(LoadDashboardDataEvent()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: () async {
                context.read<DashboardBloc>().add(LoadDashboardDataEvent());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Clean Header — no title, just greeting + actions
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Good morning 👋',
                                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Here\'s your campaign summary',
                                    style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                            // Notification bell
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: IconButton(
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF334155)),
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onPressed: () => Navigator.pushNamed(context, AppRouter.notifications),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Profile avatar
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRouter.profile),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Dashboard Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Stats Cards Row ──
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Total Spend',
                                value: '₹${state.dashboardData.totalSpend.toStringAsFixed(0)}',
                                trend: '+12.5%',
                                trendUp: true,
                                gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.campaign_rounded,
                                label: 'Campaigns',
                                value: state.dashboardData.totalCampaigns.toString(),
                                trend: '${state.dashboardData.activeCampaigns} active',
                                trendUp: true,
                                gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Quick Actions ──
                        const Text('Quick Actions', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.add_circle_rounded,
                                label: 'Create\nCampaign',
                                color: const Color(0xFF2563EB),
                                bgColor: const Color(0xFFEFF6FF),
                                onTap: () => Navigator.pushNamed(context, AppRouter.services),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.trending_up_rounded,
                                label: 'Perfor-\nmance',
                                color: const Color(0xFF16A34A),
                                bgColor: const Color(0xFFF0FDF4),
                                onTap: () => Navigator.pushNamed(context, AppRouter.analytics),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.groups_rounded,
                                label: 'Worker\nStats',
                                color: const Color(0xFFF59E0B),
                                bgColor: const Color(0xFFFEFCE8),
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.payment_rounded,
                                label: 'Pay-\nments',
                                color: const Color(0xFF8B5CF6),
                                bgColor: const Color(0xFFF5F3FF),
                                onTap: () => Navigator.pushNamed(context, AppRouter.payments),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Campaign Overview ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Campaign Overview', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRouter.campaigns),
                              child: const Row(
                                children: [
                                  Text('View all', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        CampaignOverviewCard(
                          activeCampaigns: state.dashboardData.activeCampaigns,
                          completedCampaigns: state.dashboardData.completedCampaigns,
                          totalTasks: state.dashboardData.pendingTasks +
                              state.dashboardData.inProgressTasks +
                              state.dashboardData.completedTasks,
                          completedTasks: state.dashboardData.completedTasks,
                          completionPercentage: state.dashboardData.overallCompletion,
                        ),

                        const SizedBox(height: 24),

                        // ── Recent Campaigns ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Campaigns', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRouter.campaigns),
                              child: const Row(
                                children: [
                                  Text('View all', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF2563EB)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        ...state.dashboardData.recentCampaigns.map((campaign) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: RecentCampaignItem(campaign: campaign),
                          );
                        }),

                        const SizedBox(height: 16),

                        // ── Info Banners ──
                        const InfoBanner(
                          icon: Icons.verified_outlined,
                          title: 'Quality Work. Verified Workers.',
                          description: 'We ensure reliable data and high quality through our verification process.',
                          actionText: 'Learn more',
                        ),

                        const SizedBox(height: 12),

                        const InfoBanner(
                          icon: Icons.headset_mic_outlined,
                          title: 'Need Help?',
                          description: 'Contact our support team anytime.',
                          actionText: 'Contact',
                          backgroundColor: AppColors.info,
                        ),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  // ── Beautiful Stat Card ──
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required bool trendUp,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: trendUp ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 10,
                      color: trendUp ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        color: trendUp ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Beautiful Quick Action Button ──
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF334155), fontSize: 10, fontWeight: FontWeight.w600, height: 1.3),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
