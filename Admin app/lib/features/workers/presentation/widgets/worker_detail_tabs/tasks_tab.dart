import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TasksTab extends StatefulWidget {
  final List<dynamic> tasks;

  const TasksTab({
    super.key,
    required this.tasks,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredTasks = widget.tasks.where((t) {
      if (_selectedFilter == 'All') return true;
      final status = (t['status'] ?? t['state'] ?? '').toString().toLowerCase();
      return status == _selectedFilter.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Completed', 'In Progress', 'Rejected'].map((filter) {
                final isSelected = filter == _selectedFilter;
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
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    backgroundColor: AppColors.gray100,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Task List
        Expanded(
          child: filteredTasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: AppColors.gray400),
                      SizedBox(height: 12),
                      Text(
                        'No tasks found for this worker',
                        style: TextStyle(color: AppColors.gray600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final item = filteredTasks[index];
                    final title = (item['title'] ?? item['name'] ?? item['id'] ?? 'Task #${index + 1}').toString();
                    final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();
                    final reward = item['reward'] != null ? '₹${item['reward']}' : '₹0.00';

                    Color statusColor = AppColors.success;
                    if (status.contains('REJECT')) statusColor = AppColors.error;
                    if (status.contains('PENDING') || status.contains('PROGRESS')) statusColor = AppColors.warning;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.task_alt, color: statusColor, size: 20),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text('Status: $status', style: TextStyle(color: statusColor, fontSize: 12)),
                        trailing: Text(
                          reward,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
