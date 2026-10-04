import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/kpi_card.dart';
import '../widgets/action_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../support_chat/presentation/pages/admin_chat_list_screen.dart';
import '../../../more/presentation/pages/task_reviews_queue_screen.dart';
import '../../../more/presentation/pages/kyc_queue_screen.dart';
import '../../../more/presentation/pages/payouts_queue_screen.dart';
import '../../../more/presentation/pages/finance_ledger_screen.dart';
import '../../../workers/presentation/pages/worker_directory_screen.dart';
import '../../../buyers/presentation/pages/buyer_directory_screen.dart';
import '../../../more/presentation/pages/admin_profile_screen.dart';
import '../../../../core/widgets/app_avatar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(LoadDashboardEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Command Center'),
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_rounded),
              tooltip: 'Support Chats',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminChatListScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                ),
                child: const AppAvatar(
                  name: 'Admin',
                  radius: 17,
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<DashboardBloc>().add(LoadDashboardEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is DashboardLoaded) {
              final data = state.data;
              final financial = state.financial;

              final totalWorkers = data['users']?['totalWorkers'] ?? 0;
              final activeWorkers = data['users']?['activeWorkers'] ?? 0;
              final inactiveWorkers = data['users']?['inactiveWorkers'] ?? (totalWorkers - activeWorkers);
              final totalBuyers = data['users']?['totalBuyers'] ?? 0;
              final activeBuyers = data['users']?['activeBuyers'] ?? 0;
              final inactiveBuyers = data['users']?['inactiveBuyers'] ?? (totalBuyers - activeBuyers);
              final totalUsers = data['users']?['totalUsers'] ?? (totalWorkers + totalBuyers);
              final activeUsers = data['users']?['activeUsers'] ?? (activeWorkers + activeBuyers);
              final inactiveUsers = data['users']?['inactiveUsers'] ?? (inactiveWorkers + inactiveBuyers);
              final pendingKycCount = data['queues']?['pendingKycCount'] ?? 0;
              final pendingReviewCount = data['queues']?['pendingReviewCount'] ?? 0;
              final pendingPayoutsCount = data['queues']?['pendingPayoutsCount'] ?? 0;

              final grossVolume = double.tryParse(financial['grossPlatformVolume']?.toString() ?? '0.0') ?? 0.0;
              final netMargin = double.tryParse(financial['platformNetMargin']?.toString() ?? '0.0') ?? 0.0;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(RefreshDashboardEvent());
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Environment Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'Live Production Backend',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Urgent Action Banners
                      if (pendingKycCount > 0)
                        Column(
                          children: [
                            ActionBanner(
                              icon: Icons.verified_user,
                              text: '$pendingKycCount Pending KYC Requests',
                              color: AppColors.warning,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const KycQueueScreen()),
                                );
                                if (context.mounted) {
                                  context.read<DashboardBloc>().add(LoadDashboardEvent());
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      if (pendingReviewCount > 0)
                        Column(
                          children: [
                            ActionBanner(
                              icon: Icons.rate_review,
                              text: '$pendingReviewCount Task Reviews Needed',
                              color: AppColors.error,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TaskReviewsQueueScreen()),
                                );
                                if (context.mounted) {
                                  context.read<DashboardBloc>().add(LoadDashboardEvent());
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      if (pendingPayoutsCount > 0)
                        ActionBanner(
                          icon: Icons.account_balance_wallet,
                          text: '$pendingPayoutsCount Pending Payouts',
                          color: AppColors.info,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PayoutsQueueScreen()),
                            );
                            if (context.mounted) {
                              context.read<DashboardBloc>().add(LoadDashboardEvent());
                            }
                          },
                        ),
                      
                      const SizedBox(height: 16),

                      // ── Platform Users Activity Overview ───────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.group_rounded, size: 16, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Platform Users Status',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$totalUsers Total',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const WorkerDirectoryScreen(initialFilter: 'ACTIVE'),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF16A34A),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Active Users',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  '$activeUsers',
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF16A34A)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const WorkerDirectoryScreen(initialFilter: 'INACTIVE'),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF94A3B8),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Inactive Users',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  '$inactiveUsers',
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF94A3B8)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // KPI Cards Grid
                      const Text(
                        'Master KPIs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
                        children: [
                          KpiCard(
                            title: 'Total Workers',
                            value: totalWorkers.toString(),
                            subtitle: '$activeWorkers Active • $inactiveWorkers Inactive',
                            customSubtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '● $activeWorkers Active',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '● $inactiveWorkers Inactive',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                            icon: Icons.people,
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WorkerDirectoryScreen()),
                              );
                            },
                          ),
                          KpiCard(
                            title: 'Total Buyers',
                            value: totalBuyers.toString(),
                            subtitle: '$activeBuyers Active • $inactiveBuyers Inactive',
                            customSubtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '● $activeBuyers Active',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '● $inactiveBuyers Inactive',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                            icon: Icons.business,
                            color: AppColors.secondary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BuyerDirectoryScreen()),
                              );
                            },
                          ),
                          KpiCard(
                            title: 'Pending Reviews',
                            value: pendingReviewCount.toString(),
                            subtitle: 'Awaiting Action',
                            icon: Icons.rate_review,
                            color: AppColors.warning,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TaskReviewsQueueScreen()),
                              );
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardEvent());
                              }
                            },
                          ),
                          KpiCard(
                            title: 'Pending KYC',
                            value: pendingKycCount.toString(),
                            subtitle: 'Verification Queue',
                            icon: Icons.error,
                            color: AppColors.error,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const KycQueueScreen()),
                              );
                              if (context.mounted) {
                                context.read<DashboardBloc>().add(LoadDashboardEvent());
                              }
                            },
                          ),
                          KpiCard(
                            title: 'Gross Volume',
                            value: '₹${grossVolume.toStringAsFixed(0)}',
                            subtitle: 'Total Processed',
                            icon: Icons.currency_rupee,
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FinanceLedgerScreen()),
                              );
                            },
                          ),
                          KpiCard(
                            title: 'Platform Margin',
                            value: '₹${netMargin.toStringAsFixed(0)}',
                            subtitle: 'Net Margin',
                            icon: Icons.trending_up,
                            color: AppColors.success,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FinanceLedgerScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
