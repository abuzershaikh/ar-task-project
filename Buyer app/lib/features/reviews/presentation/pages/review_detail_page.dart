import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ReviewDetailPage extends StatelessWidget {
  final String submissionId;

  const ReviewDetailPage({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Detail')),
      body: Center(
        child: Text('Review Detail - To be implemented', style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
