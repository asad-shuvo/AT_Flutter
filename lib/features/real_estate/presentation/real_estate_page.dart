import 'package:filip_at_flutter/shared/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class RealEstatePage extends StatelessWidget {
  const RealEstatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      titleKey: 'page.realEstate.title',
      descriptionKey: 'page.realEstate.description',
    );
  }
}
