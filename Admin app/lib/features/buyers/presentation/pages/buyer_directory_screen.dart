import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/buyer_card.dart';
import '../widgets/filter_chip_row.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Operations'),
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
                hintText: 'Search by Buyer ID, Company, Email, Phone',
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
            filters: const ['All', 'ACTIVE', 'SUSPENDED', 'BLOCKED'],
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
          ),

          // Buyer List
          Expanded(
            child: BlocBuilder<BuyersBloc, BuyersState>(
              builder: (context, state) {
                if (state is BuyersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BuyersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<BuyersBloc>().add(LoadBuyersEvent()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BuyersLoaded) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = state.buyers.where((b) {
                    final matchesFilter = _selectedFilter == 'All' || b.status == _selectedFilter;
                    final matchesQuery = query.isEmpty ||
                        b.name.toLowerCase().contains(query) ||
                        b.email.toLowerCase().contains(query) ||
                        b.id.toLowerCase().contains(query);
                    return matchesFilter && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No buyers found'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<BuyersBloc>().add(LoadBuyersEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
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
