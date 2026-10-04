import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Center(
        child: Text('Payments - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
