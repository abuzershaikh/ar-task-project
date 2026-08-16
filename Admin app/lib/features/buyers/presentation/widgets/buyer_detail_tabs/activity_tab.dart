import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerActivityTab extends StatelessWidget {
  final List<dynamic> activity;

  const BuyerActivityTab({super.key, this.activity = const []});

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.gray400),
            SizedBox(height: 12),
            Text('No buyer activity recorded', style: TextStyle(color: AppColors.gray600, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activity.length,
      itemBuilder: (context, index) {
        final item = activity[index];
        final type = item['type'] ?? 'BUYER_ACTIVITY';
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
    );
  }
}
