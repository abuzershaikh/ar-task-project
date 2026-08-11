import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerActivityTab extends StatelessWidget {
  final String buyerId;

  const BuyerActivityTab({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text(_getActivityText(index)),
            subtitle: Text('${index + 1} hours ago'),
          ),
        );
      },
    );
  }

  String _getActivityText(int index) {
    final activities = [
      'Campaign Created',
      'Payment Made',
      'Campaign Paused',
      'Campaign Resumed',
      'Review Approved',
    ];
    return activities[index % activities.length];
  }
}
