import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class CampaignDetailPage extends StatelessWidget {
  final String campaignId;

  const CampaignDetailPage({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Campaign: $campaignId')),
      body: Center(
        child: Text('Campaign Detail - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
