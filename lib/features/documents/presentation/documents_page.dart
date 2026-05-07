import 'package:filip_at_flutter/shared/widgets/feature_placeholder_page.dart';
import 'package:flutter/material.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      titleKey: 'page.documents.title',
      descriptionKey: 'page.documents.description',
    );
  }
}
