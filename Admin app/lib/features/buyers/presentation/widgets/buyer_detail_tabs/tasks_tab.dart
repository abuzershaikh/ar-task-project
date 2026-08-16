import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerTasksTab extends StatelessWidget {
  final List<dynamic> tasks;

  const BuyerTasksTab({
    super.key,
    this.tasks = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: AppColors.gray400),
            SizedBox(height: 12),
            Text(
              'No buyer task submissions found',
              style: TextStyle(color: AppColors.gray600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final item = tasks[index];
        final title = (item['title'] ?? item['name'] ?? 'Task #${index + 1}').toString();
        final status = (item['status'] ?? 'COMPLETED').toString().toUpperCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.assignment, color: AppColors.primary),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Status: $status'),
          ),
        );
      },
    );
  }
}
