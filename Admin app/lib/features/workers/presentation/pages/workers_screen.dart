import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/workers_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/enums.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Pending KYC', 'Suspended', 'Banned', 'At Risk'];

  @override
  void initState() {
    super.initState();
    context.read<WorkersBloc>().add(LoadWorkersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      selectedColor: AppColors.primary.withAlpha(51),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.gray600,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Workers List
          Expanded(
            child: BlocBuilder<WorkersBloc, WorkersState>(
              builder: (context, state) {
                if (state is WorkersLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is WorkersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}'),
                        ElevatedButton(
                          onPressed: () {
                            context.read<WorkersBloc>().add(LoadWorkersEvent());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is WorkersLoaded) {
                  final workers = state.workers;
                  if (workers.isEmpty) {
                    return const Center(child: Text('No workers found.'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<WorkersBloc>().add(RefreshWorkersEvent());
                      // Wait briefly to show refresh animation
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: workers.length,
                      itemBuilder: (context, index) {
                        final worker = workers[index];
                        return _WorkerCard(
                          workerId: worker.id,
                          name: worker.name,
                          email: worker.email,
                          rating: worker.rating,
                          qualityScore: 90, // Map appropriately if available
                          completionRate: 95, // Map appropriately if available
                          tasksCompleted: worker.completedTasks,
                          earnings: worker.totalEarnings.toInt(),
                          status: _parseStatus(worker.status),
                          onTap: () {
                            // Navigate to worker detail
                          },
                        );
                      },
                    ),
                  );
                }
                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  UserStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'INACTIVE': return UserStatus.inactive;
      case 'SUSPENDED': return UserStatus.suspended;
      case 'BANNED': return UserStatus.banned;
      case 'ACTIVE':
      default: return UserStatus.active;
    }
  }
}

class _WorkerCard extends StatelessWidget {
  final String workerId;
  final String name;
  final String email;
  final double rating;
  final int qualityScore;
  final int completionRate;
  final int tasksCompleted;
  final int earnings;
  final UserStatus status;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.workerId,
    required this.name,
    required this.email,
    required this.rating,
    required this.qualityScore,
    required this.completionRate,
    required this.tasksCompleted,
    required this.earnings,
    required this.status,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case UserStatus.active:
        return AppColors.success;
      case UserStatus.inactive:
        return AppColors.gray400;
      case UserStatus.suspended:
        return AppColors.warning;
      case UserStatus.banned:
        return AppColors.error;
    }
  }

  String _getStatusText() {
    return status.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(51),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isNotEmpty ? email : (workerId.length > 8 ? '#${workerId.substring(0, 8)}' : workerId),
                          style: const TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.verified, color: AppColors.info, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Score: $qualityScore',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '$completionRate% Complete',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoColumn(
                      label: 'Tasks',
                      value: tasksCompleted.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                    Container(width: 1, height: 30, color: AppColors.gray300),
                    _InfoColumn(
                      label: 'Earnings',
                      value: '₹${earnings ~/ 1000}k',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    Container(width: 1, height: 30, color: AppColors.gray300),
                    _InfoColumn(
                      label: 'Quality',
                      value: '$qualityScore',
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.gray900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}
