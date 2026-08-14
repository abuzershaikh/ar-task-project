import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/campaign_card.dart';
import '../widgets/filter_chip_row.dart';
import '../bloc/orders_bloc.dart';
import 'campaign_detail_screen.dart';

class CampaignsListScreen extends StatefulWidget {
  const CampaignsListScreen({super.key});

  @override
  State<CampaignsListScreen> createState() => _CampaignsListScreenState();
}

class _CampaignsListScreenState extends State<CampaignsListScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(LoadOrdersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns & Orders'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID, Title, or Buyer',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter Chips
          FilterChipRow(
            filters: const ['All', 'ACTIVE', 'PAUSED', 'COMPLETED', 'PENDING'],
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
          ),

          // Campaign List
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is OrdersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<OrdersBloc>().add(LoadOrdersEvent()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is OrdersLoaded) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = state.orders.where((o) {
                    final matchesFilter = _selectedFilter == 'All' || o.status == _selectedFilter;
                    final matchesQuery = query.isEmpty ||
                        o.campaignName.toLowerCase().contains(query) ||
                        o.id.toLowerCase().contains(query);
                    return matchesFilter && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No orders or campaigns found'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<OrdersBloc>().add(LoadOrdersEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final o = filtered[index];
                        final progress = o.totalTasks > 0 ? (o.completedTasks / o.totalTasks) : 0.0;
                        return CampaignCard(
                          orderId: o.id,
                          title: o.campaignName,
                          buyerName: 'Buyer #${o.buyerId.length > 6 ? o.buyerId.substring(0, 6) : o.buyerId}',
                          taskType: o.serviceType,
                          progress: progress,
                          totalTasks: o.totalTasks,
                          completedTasks: o.completedTasks,
                          buyerUnitPrice: o.rewardPerTask * 1.3,
                          platformMargin: o.rewardPerTask * 0.3,
                          workerReward: o.rewardPerTask,
                          status: o.status,
                          expiryDate: DateTime.now().add(const Duration(days: 5)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CampaignDetailScreen(orderId: o.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
