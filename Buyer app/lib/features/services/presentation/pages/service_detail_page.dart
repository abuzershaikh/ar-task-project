import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ServiceDetailPage extends StatelessWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Detail')),
      body: Center(
        child: Text('Service Detail - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
