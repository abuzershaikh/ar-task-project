import 'package:flutter/material.dart';
import '../../../services/domain/models/service_model.dart';
import 'create_campaign_page.dart';

/// DynamicCampaignCreateScreen - Delegating Wrapper to CreateCampaignPage (No Duplicate Code)
class DynamicCampaignCreateScreen extends StatelessWidget {
  final ServiceModel service;

  const DynamicCampaignCreateScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return CreateCampaignPage(serviceId: service.id);
  }
}
