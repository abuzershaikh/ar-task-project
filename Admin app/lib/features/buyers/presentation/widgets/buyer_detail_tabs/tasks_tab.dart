import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;

  const TasksTab({
    super.key,
    this.tasks = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'No buyer task submissions recorded',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final item = tasks[index];
        final title = (item['title'] ?? item['name'] ?? 'Task #${index + 1}').toString();
        final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
          ),
          child: ListTile(
            leading: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF4F46E5)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B))),
            subtitle: Text('Status: $status', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}

// Backward compatibility alias
typedef BuyerTasksTab = TasksTab;

