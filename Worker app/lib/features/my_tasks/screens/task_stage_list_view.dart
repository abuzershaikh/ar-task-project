import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/task_provider.dart';
import '../../task_detail/screens/task_detail_premium_screen.dart';
import '../widgets/my_task_card.dart';

/// Single list view for a specific task stage.
class TaskStageListView extends StatelessWidget {
  final String stage;

  const TaskStageListView({
    super.key,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final taskList = taskProvider.myTasks;

    if (taskProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00875A)),
      );
    }

    if (taskList.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF00875A),
        onRefresh: () => taskProvider.fetchMyTasks(stage),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              taskProvider.error != null
                  ? 'Error fetching tasks'
                  : 'No tasks found for "${stage.replaceAll('_', ' ').toUpperCase()}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              taskProvider.error ?? 'Pull down to refresh',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00875A),
      onRefresh: () => taskProvider.fetchMyTasks(stage),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 28),
        itemCount: taskList.length,
        itemBuilder: (context, index) {
          final task = taskList[index];
          return MyTaskCard(
            task: task,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailPremiumScreen(task: task),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
