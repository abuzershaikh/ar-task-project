import 'package:flutter/material.dart';
import '../../../campaigns/presentation/pages/create_campaign_page.dart';

/// ServicesPage - Delegates directly to CreateCampaignPage (Enterprise Clean Architecture)
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateCampaignPage();
  }
}
