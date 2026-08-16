import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/worker_model.dart';

class RatingsTab extends StatelessWidget {
  final WorkerModel worker;
  final List<dynamic> ratings;

  const RatingsTab({
    super.key,
    required this.worker,
    this.ratings = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        worker.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      const Text(
                        ' / 5.0',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${ratings.isNotEmpty ? ratings.length : (worker.completedTasks > 0 ? worker.completedTasks : 1)} ratings',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ratings.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No individual reviews recorded yet', style: TextStyle(color: AppColors.gray600)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final item = ratings[index];
                    final ratingVal = item['score'] ?? item['rating'] ?? 5.0;
                    final comment = item['comment'] ?? item['review'] ?? 'Great work!';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: AppColors.warning),
                        title: Text('Rating: $ratingVal ⭐'),
                        subtitle: Text(comment.toString()),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
