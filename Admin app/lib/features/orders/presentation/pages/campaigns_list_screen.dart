import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text(
          'Campaigns & Orders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Campaigns',
            onPressed: () => context.read<OrdersBloc>().add(LoadOrdersEvent()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Metric Summary Strip
          BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              int totalCampaigns = 0;
              int activeCampaigns = 0;
              int totalTasks = 0;
              double totalBudget = 0.0;

              if (state is OrdersLoaded) {
                totalCampaigns = state.orders.length;
                activeCampaigns = state.orders.where((o) => o.status.toUpperCase() == 'ACTIVE').length;
                for (var o in state.orders) {
                  totalTasks += o.totalTasks;
                  totalBudget += o.totalBudget;
                }
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDCFCE7), Color(0xFFA7F3D0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6EE7B7), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08059669),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('Campaigns', '$totalCampaigns', const Color(0xFF064E3B)),
                    Container(height: 24, width: 1, color: const Color(0xFF6EE7B7)),
                    _buildMetricCol('Active', '$activeCampaigns', const Color(0xFF047857)),
                    Container(height: 24, width: 1, color: const Color(0xFF6EE7B7)),
                    _buildMetricCol('Tasks', '$totalTasks', const Color(0xFF065F46)),
                    Container(height: 24, width: 1, color: const Color(0xFF6EE7B7)),
                    _buildMetricCol('Budget', '₹${totalBudget.toStringAsFixed(0)}', const Color(0xFF064E3B)),
                  ],
                ),
              );
            },
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06059669),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF064E3B)),
                decoration: InputDecoration(
                  hintText: 'Search by Order ID, Campaign Name, or Buyer...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF059669), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }

                if (state is OrdersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
                        const SizedBox(height: 8),
                        Text(state.message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.read<OrdersBloc>().add(LoadOrdersEvent()),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is OrdersLoaded) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = state.orders.where((o) {
                    final matchesFilter = _selectedFilter == 'All' || o.status.toUpperCase() == _selectedFilter.toUpperCase();
                    final matchesQuery = query.isEmpty ||
                        o.campaignName.toLowerCase().contains(query) ||
                        o.id.toLowerCase().contains(query) ||
                        o.buyerId.toLowerCase().contains(query);
                    return matchesFilter && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Text(
                            'No campaigns match the filter',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF059669),
                    onRefresh: () async {
                      context.read<OrdersBloc>().add(LoadOrdersEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final o = filtered[index];
                        final progress = o.totalTasks > 0 ? (o.completedTasks / o.totalTasks) : 0.0;
                        final buyerShort = o.buyerId.length > 6 ? o.buyerId.substring(0, 6) : o.buyerId;

                        return CampaignCard(
                          orderId: o.id,
                          title: o.campaignName,
                          buyerName: o.buyerName.isNotEmpty ? o.buyerName : (buyerShort.isNotEmpty ? 'Buyer #$buyerShort' : 'Direct Order'),
                          buyerEmail: o.buyerEmail,
                          taskType: o.serviceType,
                          progress: progress,
                          totalTasks: o.totalTasks,
                          completedTasks: o.completedTasks,
                          buyerUnitPrice: o.buyerUnitPrice,
                          platformMargin: o.platformMargin,
                          workerReward: o.workerReward,
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

  Widget _buildMetricCol(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF047857), fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

