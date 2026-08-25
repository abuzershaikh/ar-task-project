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
                      Icon(Icons.reviews_outlined, size: 40, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 8),
                      Text(
                        'No specific review logs found',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star_rounded, color: Color(0xFFD97706)),
                        title: Text(item['title'] ?? 'Review', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B))),
                        subtitle: Text(item['content'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// Backward compatibility alias
typedef BuyerReviewsTab = ReviewsTab;

