import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/buyer_card.dart';
import '../bloc/buyers_bloc.dart';
import 'buyer_detail_screen.dart';

class BuyerDirectoryScreen extends StatefulWidget {
  const BuyerDirectoryScreen({super.key});

  @override
  State<BuyerDirectoryScreen> createState() => _BuyerDirectoryScreenState();
}

class _BuyerDirectoryScreenState extends State<BuyerDirectoryScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BuyersBloc>().add(LoadBuyersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        titleSpacing: 14,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.business_center_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Buyer Operations',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: () => context.read<BuyersBloc>().add(LoadBuyersEvent()),
          ),
        ],
      ),
      body: BlocBuilder<BuyersBloc, BuyersState>(
        builder: (context, state) {
          if (state is BuyersLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
          }

          if (state is BuyersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                    onPressed: () => context.read<BuyersBloc>().add(LoadBuyersEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is BuyersLoaded) {
            final allBuyers = state.buyers;
            final query = _searchController.text.trim().toLowerCase();
            final filtered = allBuyers.where((b) {
              final matchesFilter = _selectedFilter == 'All' || b.status.toUpperCase() == _selectedFilter.toUpperCase();
              final matchesQuery = query.isEmpty ||
                  b.name.toLowerCase().contains(query) ||
                  b.email.toLowerCase().contains(query) ||
                  b.id.toLowerCase().contains(query);
              return matchesFilter && matchesQuery;
            }).toList();

            final int activeCount = allBuyers.where((b) => b.status.toUpperCase() == 'ACTIVE').length;
            final double totalPlatformSpend = allBuyers.fold(0.0, (sum, b) => sum + b.totalSpend);

            return Column(
              children: [
                // ── 1. Top Metrics Strip ─────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC4B5FD), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A4F46E5),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Total Buyers', '${allBuyers.length}', const Color(0xFF1E1B4B)),
                      Container(height: 24, width: 1, color: const Color(0xFFC4B5FD)),
                      _buildMetricItem('Active', '$activeCount', const Color(0xFF16A34A)),
                      Container(height: 24, width: 1, color: const Color(0xFFC4B5FD)),
                      _buildMetricItem(
                        'Total Volume',
                        totalPlatformSpend >= 1000 ? '₹${(totalPlatformSpend / 1000).toStringAsFixed(1)}K' : '₹${totalPlatformSpend.toStringAsFixed(0)}',
                        const Color(0xFF4F46E5),
                      ),
                      Container(height: 24, width: 1, color: const Color(0xFFC4B5FD)),
                      _buildMetricItem('Risk Score', 'Low 🟢', const Color(0xFF16A34A)),
                    ],
                  ),
                ),

                // ── 2. Compact Search Bar ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x064F46E5),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Color(0xFF1E1B4B), fontSize: 12),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by Buyer ID, Company, Email...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4F46E5), size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF6B7280), size: 16),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── 3. Filter Chips ──────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: ['All', 'ACTIVE', 'SUSPENDED', 'BLOCKED'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF4338CA),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF4F46E5),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFDDD6FE),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // ── 4. Buyer Cards List ──────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.business_center_outlined, size: 48, color: Color(0xFF9CA3AF)),
                              const SizedBox(height: 10),
                              const Text('No buyers matching criteria', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF4F46E5),
                          backgroundColor: Colors.white,
                          onRefresh: () async {
                            context.read<BuyersBloc>().add(LoadBuyersEvent());
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final b = filtered[index];
                              return BuyerCard(
                                buyerId: b.id,
                                companyName: b.name,
                                email: b.email,
                                totalOrders: b.totalOrders,
                                activeCampaigns: b.activeCampaigns,
                                totalSpend: b.totalSpend,
                                status: b.status,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BuyerDetailScreen(buyerId: b.id),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: Color(0xFF4338CA), fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


