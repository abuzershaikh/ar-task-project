import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications, color: AppColors.primary),
            ),
            title: Text(
              'Campaign activated',
              style: AppTextStyles.labelLarge,
            ),
            subtitle: Text(
              'Your campaign #CAMP-001 is now active',
              style: AppTextStyles.bodySmall,
            ),
            trailing: Text(
              '2h ago',
              style: AppTextStyles.caption,
            ),
          );
        },
      ),
    );
  }
}
