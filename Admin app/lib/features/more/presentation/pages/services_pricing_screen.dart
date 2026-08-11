import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ServicesPricingScreen extends StatelessWidget {
  const ServicesPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Pricing Engine'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showAddServiceDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          final services = [
            {'name': 'YouTube Like', 'type': 'YOUTUBE_LIKE', 'status': 'ACTIVE'},
            {'name': 'YouTube Comment', 'type': 'YOUTUBE_COMMENT', 'status': 'ACTIVE'},
            {'name': 'Instagram Like', 'type': 'INSTAGRAM_LIKE', 'status': 'ACTIVE'},
            {'name': 'Instagram Follow', 'type': 'INSTAGRAM_FOLLOW', 'status': 'ACTIVE'},
            {'name': 'Twitter Retweet', 'type': 'TWITTER_RETWEET', 'status': 'ACTIVE'},
            {'name': 'Facebook Like', 'type': 'FACEBOOK_LIKE', 'status': 'INACTIVE'},
            {'name': 'TikTok View', 'type': 'TIKTOK_VIEW', 'status': 'ACTIVE'},
            {'name': 'App Download', 'type': 'APP_DOWNLOAD', 'status': 'ACTIVE'},
          ];
          
          final service = services[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag, color: AppColors.primary),
              ),
              title: Text(service['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(service['type']!),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: service['status'] == 'ACTIVE' 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.gray300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  service['status']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: service['status'] == 'ACTIVE' ? AppColors.success : AppColors.gray600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildPricingRow('Buyer Unit Price', '₹2.00'),
                      _buildPricingRow('Platform Margin (25%)', '₹0.50'),
                      _buildPricingRow('Net Worker Reward', '₹1.50'),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      const Text('Live Preview Calculator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Buyer Price (₹)',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Margin %',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Pricing'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.history, size: 18),
                              label: const Text('History'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Service Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Buyer Unit Price (₹)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Platform Margin %'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create')),
        ],
      ),
    );
  }
}
