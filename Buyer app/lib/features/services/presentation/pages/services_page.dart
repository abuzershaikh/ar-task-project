import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'id': '1', 'name': 'Product Testing', 'icon': Icons.shopping_bag_outlined, 'price': 25},
      {'id': '2', 'name': 'Survey', 'icon': Icons.quiz_outlined, 'price': 15},
      {'id': '3', 'name': 'Feedback', 'icon': Icons.rate_review_outlined, 'price': 20},
      {'id': '4', 'name': 'Store Visit', 'icon': Icons.store_outlined, 'price': 30},
      {'id': '5', 'name': 'Hotel Audit', 'icon': Icons.hotel_outlined, 'price': 40},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  service['icon'] as IconData,
                  color: AppColors.primary,
                ),
              ),
              title: Text(service['name'] as String, style: AppTextStyles.labelLarge),
              subtitle: Text('₹${service['price']} / task', style: AppTextStyles.bodySmall),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.serviceDetail,
                    arguments: service['id'],
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Buy Service'),
              ),
            ),
          );
        },
      ),
    );
  }
}
