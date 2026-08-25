import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/worker_card.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        titleSpacing: 14,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Worker Operations',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: () => context.read<WorkersBloc>().add(LoadWorkersEvent()),
          ),
        ],
      ),
      body: BlocBuilder<WorkersBloc, WorkersState>(
        builder: (context, state) {
          if (state is WorkersLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
          }

          if (state is WorkersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                    onPressed: () => context.read<WorkersBloc>().add(LoadWorkersEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is WorkersLoaded) {
            final allWorkers = state.workers;
            final query = _searchController.text.trim().toLowerCase();
            final filtered = allWorkers.where((w) {
              final statusMatch = _selectedFilter == 'All' ||
                  w.status.toUpperCase() == _selectedFilter.toUpperCase() ||
                  (_selectedFilter == 'KYC' && w.kycStatus == 'VERIFIED');
              final queryMatch = query.isEmpty ||
                  w.name.toLowerCase().contains(query) ||
                  w.email.toLowerCase().contains(query) ||
                  w.phone.toLowerCase().contains(query) ||
                  w.id.toLowerCase().contains(query);
              return statusMatch && queryMatch;
            }).toList();

            final int activeCount = allWorkers.where((w) => w.status.toUpperCase() == 'ACTIVE').length;
            final int kycCount = allWorkers.where((w) => w.kycStatus == 'VERIFIED').length;

            return Column(
              children: [
                // ── 1. Top Metrics Strip ─────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7DD3FC), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0284C7),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Workers', '${allWorkers.length}', const Color(0xFF0F172A)),
                      Container(height: 24, width: 1, color: const Color(0xFF7DD3FC)),
                      _buildMetricItem('Active', '$activeCount', const Color(0xFF16A34A)),
                      Container(height: 24, width: 1, color: const Color(0xFF7DD3FC)),
                      _buildMetricItem('KYC Verified', '$kycCount', const Color(0xFF0284C7)),
                      Container(height: 24, width: 1, color: const Color(0xFF7DD3FC)),
                      _buildMetricItem('Platform Rating', '4.9 ★', const Color(0xFFD97706)),
                    ],
                  ),
                ),

                // ── 2. Compact Search Input ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060284C7),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by Worker ID, Name, Phone, Email...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 16),
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
                    children: ['All', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'KYC'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF0369A1),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
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

                // ── 4. Worker Cards List ─────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              const Text('No workers matching criteria', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF0284C7),
                          backgroundColor: Colors.white,
                          onRefresh: () async {
                            context.read<WorkersBloc>().add(LoadWorkersEvent());
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final w = filtered[index];
                              return WorkerCard(
                                workerId: w.id,
                                name: w.name,
                                email: w.email,
                                phone: w.phone,
                                rating: w.rating,
                                score: 92.0,
                                totalTasks: w.completedTasks,
                                kycVerified: w.kycStatus == 'VERIFIED' || w.kycStatus == 'APPROVED',
                                status: w.status,
                                totalEarned: w.totalEarnings,
                                availableBalance: w.totalEarnings,
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
        Text(label, style: const TextStyle(color: Color(0xFF0369A1), fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }
}


