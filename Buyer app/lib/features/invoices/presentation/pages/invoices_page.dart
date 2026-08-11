import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: Center(
        child: Text('Invoices - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
