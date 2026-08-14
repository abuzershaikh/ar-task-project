import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/info_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FC),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
            );
          }

          if (state is DashboardError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.wifi_off_rounded, size: 28, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => context.read<DashboardBloc>().add(LoadDashboardDataEvent()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DashboardLoaded) {
            final d = state.dashboardData;
            final totalTasks = d.pendingTasks + d.inProgressTasks + d.completedTasks;

            return FadeTransition(
              opacity: _fadeController,
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                backgroundColor: Colors.white,
                displacement: 40,
                onRefresh: () async {
                  context.read<DashboardBloc>().add(LoadDashboardDataEvent());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.zero,
                  children: [
                    // ─── HEADER ───
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_greeting()} 👋',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const Text(
                                    'Campaign Dashboard',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                            // Search
                            _HeaderIcon(
                              icon: Icons.search_rounded,
                              onTap: () {},
                            ),
                            const SizedBox(width: 8),
                            // Notifications
                            _HeaderIcon(
                              icon: Icons.notifications_none_rounded,
                              badge: true,
                              onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── HERO SUMMARY CARD ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Spend',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.trending_up_rounded, color: Color(0xFF86EFAC), size: 10),
                                      SizedBox(width: 3),
                                      Text('+12.5%', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 9, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${d.totalSpend.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Spacer(),
                                // Mini completion ring
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: d.overallCompletion / 100,
                                        strokeWidth: 3,
                                        backgroundColor: Colors.white.withOpacity(0.15),
                                        valueColor: const AlwaysStoppedAnimation(Color(0xFF86EFAC)),
                                      ),
                                      Text(
                                        '${d.overallCompletion.toInt()}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ─── MINI STATS — 4 Tiny Cards ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          _MiniStat(
                            icon: Icons.campaign_rounded,
                            label: 'Active',
                            value: '${d.activeCampaigns}',
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          _MiniStat(
                            icon: Icons.check_circle_rounded,
                            label: 'Done',
                            value: '${d.completedCampaigns}',
                            color: const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          _MiniStat(
                            icon: Icons.pending_actions_rounded,
                            label: 'Pending',
                            value: '${d.pendingTasks}',
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          _MiniStat(
                            icon: Icons.task_alt_rounded,
                            label: 'Tasks',
                            value: '$totalTasks',
                            color: const Color(0xFF3B82F6),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ─── QUICK ACTIONS ───
                    _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 82,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        children: [
                          _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'New Campaign',
                            color: const Color(0xFF4F46E5),
                            onTap: () => Navigator.pushNamed(context, AppRouter.services),
                          ),
                          _QuickAction(
                            icon: Icons.grid_view_rounded,
                            label: 'Services',
                            color: const Color(0xFF9333EA),
                            onTap: () => Navigator.pushNamed(context, AppRouter.services),
                          ),
                          _QuickAction(
                            icon: Icons.rate_review_outlined,
                            label: 'Reviews',
                            color: const Color(0xFFD97706),
                            onTap: () => Navigator.pushNamed(context, AppRouter.reviews),
                          ),
                          _QuickAction(
                            icon: Icons.insights_rounded,
                            label: 'Analytics',
                            color: const Color(0xFF059669),
                            onTap: () => Navigator.pushNamed(context, AppRouter.analytics),
                          ),
                          _QuickAction(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Payments',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.pushNamed(context, AppRouter.payments),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ─── TASK PROGRESS ───
                    _SectionHeader(title: 'Task Progress'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _ProgressChip(
                                  label: 'Completed',
                                  value: d.completedTasks,
                                  total: totalTasks > 0 ? totalTasks : 1,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                _ProgressChip(
                                  label: 'In Progress',
                                  value: d.inProgressTasks,
                                  total: totalTasks > 0 ? totalTasks : 1,
                                  color: const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 8),
                                _ProgressChip(
                                  label: 'Pending',
                                  value: d.pendingTasks,
                                  total: totalTasks > 0 ? totalTasks : 1,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Stacked progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 6,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: d.completedTasks > 0 ? d.completedTasks : 0,
                                      child: Container(color: const Color(0xFF10B981)),
                                    ),
                                    Expanded(
                                      flex: d.inProgressTasks > 0 ? d.inProgressTasks : 0,
                                      child: Container(color: const Color(0xFF3B82F6)),
                                    ),
                                    Expanded(
                                      flex: d.pendingTasks > 0 ? d.pendingTasks : 0,
                                      child: Container(color: const Color(0xFFFBBF24)),
                                    ),
                                    if (totalTasks == 0)
                                      Expanded(flex: 1, child: Container(color: const Color(0xFFE5E7EB))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ─── RECENT CAMPAIGNS ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Campaigns',
                            style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRouter.campaigns),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'View all',
                                style: TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Campaign List
                    ...d.recentCampaigns.map((campaign) {
                      final progress = campaign.totalTasks > 0
                          ? campaign.completedTasks / campaign.totalTasks
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRouter.campaignDetail, arguments: campaign.id),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Service Icon
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _statusColor(campaign.status).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _serviceIcon(campaign.serviceType),
                                    color: _statusColor(campaign.status),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              campaign.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(campaign.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              campaign.status.toUpperCase(),
                                              style: TextStyle(
                                                color: _statusColor(campaign.status),
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          // Progress bar
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(3),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 4,
                                                backgroundColor: const Color(0xFFF1F5F9),
                                                valueColor: AlwaysStoppedAnimation(_statusColor(campaign.status)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${campaign.completedTasks}/${campaign.totalTasks}',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    // ─── INFO BANNERS ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _CompactBanner(
                        icon: Icons.verified_rounded,
                        title: 'Verified Workers',
                        subtitle: 'Quality assured through our vetting process',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _CompactBanner(
                        icon: Icons.support_agent_rounded,
                        title: 'Need Help?',
                        subtitle: 'Our support team is available 24/7',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),

                    // Bottom padding for nav bar
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                  ],
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF6366F1);
      case 'in_progress':
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'paused':
        return const Color(0xFF6B7280);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _serviceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'product_testing':
        return Icons.shopping_bag_outlined;
      case 'survey':
        return Icons.quiz_outlined;
      case 'feedback':
        return Icons.rate_review_outlined;
      case 'store_visit':
        return Icons.store_outlined;
      case 'hotel_audit':
        return Icons.hotel_outlined;
      default:
        return Icons.task_outlined;
    }
  }
}

// ─────────────────────────────────────────────────
// REUSABLE MINI WIDGETS
// ─────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, this.badge = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF475569)),
            if (badge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressChip({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _CompactBanner({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }
}
