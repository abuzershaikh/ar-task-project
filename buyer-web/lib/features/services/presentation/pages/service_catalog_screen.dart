import 'package:flutter/material.dart';
import '../../../campaigns/presentation/pages/create_campaign_page.dart';

/// ServiceCatalogScreen - Clean Alias delegating to CreateCampaignPage (No Duplicate Code)
class ServiceCatalogScreen extends StatelessWidget {
  const ServiceCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateCampaignPage();
  }
}
