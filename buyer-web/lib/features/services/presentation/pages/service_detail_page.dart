import 'package:flutter/material.dart';
import '../../../campaigns/presentation/pages/create_campaign_page.dart';

class ServiceDetailPage extends StatelessWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return CreateCampaignPage(serviceId: serviceId);
  }
}

