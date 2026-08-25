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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Completed', 'In Progress', 'Rejected'].map((filter) {
                final isSelected = filter == _selectedFilter;
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
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Task List
        Expanded(
          child: filteredTasks.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 44, color: Color(0xFF94A3B8)),
                      SizedBox(height: 10),
                      Text(
                        'No task records found for this worker',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final item = filteredTasks[index];
                    final title = (item['title'] ?? item['name'] ?? item['id'] ?? 'Task #${index + 1}').toString();
                    final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();
                    final reward = item['rewardAmount'] != null ? '₹${item['rewardAmount']}' : (item['reward'] != null ? '₹${item['reward']}' : '₹0.00');

                    Color statusColor = const Color(0xFF16A34A);
                    Color bgColor = const Color(0xFFDCFCE7);
                    if (status.contains('REJECT')) {
                      statusColor = const Color(0xFFDC2626);
                      bgColor = const Color(0xFFFEE2E2);
                    }
                    if (status.contains('PENDING') || status.contains('PROGRESS')) {
                      statusColor = const Color(0xFFD97706);
                      bgColor = const Color(0xFFFEF3C7);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.task_alt_rounded, color: statusColor, size: 18),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        subtitle: Text('Status: $status', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        trailing: Text(
                          reward,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0284C7)),
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

