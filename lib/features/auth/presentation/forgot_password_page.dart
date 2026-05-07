import 'package:filip_at_flutter/shared/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      titleKey: 'forgotPassword.title',
      descriptionKey: 'forgotPassword.description',
    );
  }
}
