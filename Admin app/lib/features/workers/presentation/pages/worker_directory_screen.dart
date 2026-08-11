import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/worker_card.dart';
import '../../presentation/widgets/filter_chip_row.dart';
import 'worker_detail_screen.dart';

class WorkerDirectoryScreen extends StatefulWidget {
  const WorkerDirectoryScreen({super.key});

  @override
  State<WorkerDirectoryScreen> createState() => _WorkerDirectoryScreenState();
}

class _WorkerDirectoryScreenState extends State<WorkerDirectoryScreen> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Highest Score';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sortOptions = [
    'Highest Score',
    'Highest Rating',
    'Most Tasks',
    'Lowest Completion',
    'Highest Earnings',
    'Recent Activity',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Operations'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            itemBuilder: (context) => _sortOptions
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (_selectedSort == option)
                            const Icon(Icons.check, color: AppColors.primary, size: 18),
                          if (_selectedSort == option) const SizedBox(width: 8),
                          Text(option),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
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
                hintText: 'Search by Worker ID, Name, Phone, Email',
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
              'Inactive',
              'KYC Pending',
              'KYC Rejected',
              'Suspended',
              'Banned',
              'High Risk',
            ],
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),

          // Worker List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 20, // TODO: Replace with actual data
                itemBuilder: (context, index) {
                  return WorkerCard(
                    workerId: 'W-${1000 + index}',
                    name: 'Worker ${index + 1}',
                    phone: '+91 XXXXXXXX${12 + index}',
                    rating: 4.5 + (index % 5) * 0.1,
                    score: 85.0 + (index % 15),
                    totalTasks: 1000 + (index * 100),
                    kycVerified: index % 3 != 0,
                    status: index % 6 == 0 ? 'SUSPENDED' : 'ACTIVE',
                    totalEarned: 15000.0 + (index * 1000),
                    availableBalance: 2000.0 + (index * 100),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerDetailScreen(
                            workerId: 'W-${1000 + index}',
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
