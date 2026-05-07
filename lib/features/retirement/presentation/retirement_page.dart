import 'package:filip_at_flutter/shared/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class RetirementPage extends StatelessWidget {
  const RetirementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      titleKey: 'page.retirement.title',
      descriptionKey: 'page.retirement.description',
    );
  }
}
