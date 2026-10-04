import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: Text('Forgot Password Page - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
