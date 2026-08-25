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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080284C7),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 36),
                      const SizedBox(width: 8),
                      Text(
                        worker.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        ' / 5.0',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Overall Platform Quality Rating',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 14),
          
          ratings.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 40, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text(
                        'No custom buyer reviews submitted yet',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final item = ratings[index];
                    final ratingVal = item['score'] ?? item['rating'] ?? 5.0;
                    final comment = item['comment'] ?? item['review'] ?? 'Excellent submission!';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
                        title: Text('Rating: $ratingVal ⭐', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                        subtitle: Text(comment.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

