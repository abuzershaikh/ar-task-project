import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ActivityTab extends StatelessWidget {
  final List<dynamic> activity;

  const ActivityTab({
    super.key,
    this.activity = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Logs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          activity.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No activity logs recorded yet', style: TextStyle(color: AppColors.gray600)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activity.length,
                  itemBuilder: (context, index) {
                    final item = activity[index];
                    final type = item['type'] ?? 'ACTIVITY';
                    final timestamp = item['timestamp']?.toString() ?? 'Recent';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: AppColors.primary),
                        title: Text(type.toString()),
                        subtitle: Text(timestamp),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
