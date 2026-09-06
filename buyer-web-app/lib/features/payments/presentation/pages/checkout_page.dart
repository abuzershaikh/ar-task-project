import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class CheckoutPage extends StatelessWidget {
  final Map<String, dynamic> checkoutData;

  const CheckoutPage({super.key, required this.checkoutData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: Text('Checkout - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
