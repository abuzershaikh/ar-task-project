import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class RatingsTab extends StatelessWidget {
  final String workerId;

  const RatingsTab({super.key, required this.workerId});

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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: AppColors.warning, size: 32),
                      SizedBox(width: 8),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        ' / 5.0',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Based on 245 ratings',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Rating Histogram
                  _buildRatingBar(5, 180, 245),
                  _buildRatingBar(4, 45, 245),
                  _buildRatingBar(3, 12, 245),
                  _buildRatingBar(2, 5, 245),
                  _buildRatingBar(1, 3, 245),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Feedback
          const Text(
            'Recent Buyer Feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10,
            itemBuilder: (context, index) {
              final ratings = [5, 5, 4, 5, 4, 5, 3, 5, 4, 5];
              final rating = ratings[index];
              
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
                          const Expanded(
                            child: Text(
                              'YouTube Like Campaign',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: AppColors.warning,
                              size: 16,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Excellent work! Tasks completed on time with good quality proof submissions.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ABC Digital Pvt Ltd',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                          Text(
                            '${index + 1} days ago',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = count / total;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text(
                  '$stars',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: AppColors.warning, size: 14),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: AppColors.gray200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
