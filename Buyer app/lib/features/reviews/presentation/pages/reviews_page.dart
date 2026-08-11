import 'package:flutter/material.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReviewList(context, 'pending'),
            _buildReviewList(context, 'approved'),
            _buildReviewList(context, 'rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(BuildContext context, String type) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Task #T-1024',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (type == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Pending', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Campaign: Product Testing'),
            const SizedBox(height: 4),
            const Text('📷 2 Images   🔗 1 Link'),
            const SizedBox(height: 8),
            const Text('Submitted 8 min ago', style: TextStyle(fontSize: 12)),
            if (type == 'pending') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // Navigate to review detail
                },
                child: const Text('Review'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
