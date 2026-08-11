import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerTasksTab extends StatelessWidget {
  final String buyerId;

  const BuyerTasksTab({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.task, color: AppColors.primary),
            title: Text('Task #T-${10000 + index}'),
            subtitle: Text('Campaign: ORD-1001 • Worker: W-${1000 + index}'),
            trailing: const Chip(
              label: Text('Approved', style: TextStyle(fontSize: 11)),
              backgroundColor: Color(0xFFD1FAE5),
              labelStyle: TextStyle(color: AppColors.success),
            ),
          ),
        );
      },
    );
  }
}
