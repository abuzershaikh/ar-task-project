import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class CreateCampaignPage extends StatelessWidget {
  final String? serviceId;

  const CreateCampaignPage({super.key, this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Campaign')),
      body: Center(
        child: Text('Create Campaign - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
