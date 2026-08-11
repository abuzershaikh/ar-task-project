import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/campaign_card.dart';
import '../widgets/filter_chip_row.dart';
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
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filter Chips
          FilterChipRow(
            filters: const [
              'All',
              'Payment Pending',
              'Active',
              'Paused',
              'Completed',
              'Failed/Blocked',
            ],
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),

          // Campaign List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 10, // TODO: Replace with actual data
                itemBuilder: (context, index) {
                  return CampaignCard(
                    orderId: 'ORD-${1000 + index}',
                    title: 'YouTube Like Campaign - Tech Channel',
                    buyerName: 'ABC Digital Pvt Ltd',
                    taskType: 'YOUTUBE_LIKE',
                    progress: 0.45 + (index * 0.05),
                    totalTasks: 1000,
                    completedTasks: 450 + (index * 50),
                    buyerUnitPrice: 2.00,
                    platformMargin: 0.50,
                    workerReward: 1.50,
                    status: index % 4 == 0
                        ? 'ACTIVE'
                        : index % 4 == 1
                            ? 'PAUSED'
                            : index % 4 == 2
                                ? 'COMPLETED'
                                : 'PAYMENT_PENDING',
                    expiryDate: DateTime.now().add(Duration(days: 7 - index)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CampaignDetailScreen(orderId: 'ORD-${1000 + index}'),
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
