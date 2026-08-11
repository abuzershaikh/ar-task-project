import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BuyerOrdersTab extends StatelessWidget {
  final String buyerId;

  const BuyerOrdersTab({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ORD-${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('YouTube Like Campaign', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: 0.75, backgroundColor: AppColors.gray200, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('750 / 1000 tasks', style: TextStyle(fontSize: 12)),
                    Text('Budget: ₹2,000', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
