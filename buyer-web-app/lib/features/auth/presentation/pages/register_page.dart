import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Text('Register Page - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
