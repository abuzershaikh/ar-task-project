import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Center(
        child: Text('Support - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
