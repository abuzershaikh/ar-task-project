import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: Center(
        child: Text('Help Center - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
