import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/buyer_card.dart';
import '../widgets/filter_chip_row.dart';
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
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filter Chips
          FilterChipRow(
            filters: const [
              'All',
              'Active',
              'Suspended',
              'Blocked',
              'Payment Issues',
            ],
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),

          // Buyer List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {},
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 15,
                itemBuilder: (context, index) {
                  return BuyerCard(
                    buyerId: 'B-${100 + index}',
                    companyName: 'Company ${index + 1} Pvt Ltd',
                    email: 'contact${index}@company.com',
                    totalOrders: 100 + (index * 10),
                    activeCampaigns: 5 + (index % 5),
                    totalSpend: 200000.0 + (index * 10000),
                    status: index % 6 == 0 ? 'SUSPENDED' : 'ACTIVE',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuyerDetailScreen(
                            buyerId: 'B-${100 + index}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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
