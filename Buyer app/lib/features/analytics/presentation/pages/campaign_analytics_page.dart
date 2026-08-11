import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class CampaignAnalyticsPage extends StatelessWidget {
  final String campaignId;

  const CampaignAnalyticsPage({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Analytics')),
      body: Center(
        child: Text('Campaign Analytics - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
