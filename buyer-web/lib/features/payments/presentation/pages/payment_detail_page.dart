import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentDetailPage extends StatelessWidget {
  final String paymentId;

  const PaymentDetailPage({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Detail')),
      body: Center(
        child: Text('Payment Detail - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
