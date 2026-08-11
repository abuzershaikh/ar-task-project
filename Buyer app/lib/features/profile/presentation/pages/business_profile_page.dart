import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class BusinessProfilePage extends StatelessWidget {
  const BusinessProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: Center(
        child: Text('Business Profile - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
