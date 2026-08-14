import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/worker_card.dart';
import '../widgets/filter_chip_row.dart';
import '../bloc/workers_bloc.dart';
import 'worker_detail_screen.dart';

class WorkerDirectoryScreen extends StatefulWidget {
  const WorkerDirectoryScreen({super.key});

  @override
  State<WorkerDirectoryScreen> createState() => _WorkerDirectoryScreenState();
}

class _WorkerDirectoryScreenState extends State<WorkerDirectoryScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WorkersBloc>().add(LoadWorkersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Operations'),
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
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filter Chips
          FilterChipRow(
            filters: const ['All', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED'],
            selectedFilter: _selectedFilter,
            onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
          ),

          // Worker List
          Expanded(
            child: BlocBuilder<WorkersBloc, WorkersState>(
              builder: (context, state) {
                if (state is WorkersLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WorkersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<WorkersBloc>().add(LoadWorkersEvent()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is WorkersLoaded) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = state.workers.where((w) {
                    final matchesFilter = _selectedFilter == 'All' || w.status == _selectedFilter;
                    final matchesQuery = query.isEmpty ||
                        w.name.toLowerCase().contains(query) ||
                        w.email.toLowerCase().contains(query) ||
                        w.id.toLowerCase().contains(query);
                    return matchesFilter && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No workers found'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WorkersBloc>().add(LoadWorkersEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final w = filtered[index];
                        return WorkerCard(
                          workerId: w.id,
                          name: w.name,
                          phone: w.phone,
                          rating: w.rating,
                          score: 90.0,
                          totalTasks: w.completedTasks,
                          kycVerified: w.kycStatus == 'VERIFIED',
                          status: w.status,
                          totalEarned: w.totalEarnings,
                          availableBalance: 0.0,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkerDetailScreen(workerId: w.id),
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
