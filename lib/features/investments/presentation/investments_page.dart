import 'package:filip_at_flutter/shared/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class InvestmentsPage extends StatelessWidget {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      titleKey: 'page.investments.title',
      descriptionKey: 'page.investments.description',
    );
  }
}
