import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/buyer_model.dart';

class ReviewsTab extends StatelessWidget {
  final BuyerModel? buyer;
  final List<dynamic> reviews;

  const ReviewsTab({
    super.key,
    this.buyer,
    this.reviews = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x084F46E5),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rate_review_rounded, color: Color(0xFF4F46E5), size: 32),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    buyer?.name ?? 'Buyer Account',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Verified Spend: ₹${(buyer?.totalSpend ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x084F46E5),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.feedback_outlined, size: 18, color: Color(0xFF4F46E5)),
                      SizedBox(width: 8),
                      Text(
                        'Buyer Feedback & Task Evaluation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  _buildStatRow('Task Feedback Policy', 'Standard Quality Review'),
                  _buildStatRow('Worker Task Dispute Flags', '0 Recorded Flags'),
                  _buildStatRow('Commercial Rating Status', (buyer?.totalOrders ?? 0) > 0 ? 'Active Reviewer' : 'New Buyer'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          reviews.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 40, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 8),
                      Text(
                        'No custom worker reviews recorded yet',
                        style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Feedback submitted by this buyer on completed tasks will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final item = reviews[index];
                    final score = item['rating'] ?? item['score'] ?? 5;
                    final title = item['title'] ?? item['taskTitle'] ?? 'Task Review #${index + 1}';
                    final comment = item['comment'] ?? item['content'] ?? 'Verified submission';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star_rounded, color: Color(0xFFD97706)),
                        title: Text('$title ($score ⭐)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B))),
                        subtitle: Text(comment.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
        ],
      ),
    );
  }
}

// Backward compatibility alias
typedef BuyerReviewsTab = ReviewsTab;

