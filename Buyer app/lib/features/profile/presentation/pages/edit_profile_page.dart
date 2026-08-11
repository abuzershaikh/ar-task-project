import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: Text('Edit Profile - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
