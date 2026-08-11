import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Detail')),
      body: Center(
        child: Text('Invoice Detail - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
