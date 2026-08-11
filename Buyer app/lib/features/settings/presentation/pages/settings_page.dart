import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Text('Settings - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
