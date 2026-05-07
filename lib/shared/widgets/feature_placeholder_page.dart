import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.titleKey,
    required this.descriptionKey,
  });

  final String titleKey;
  final String descriptionKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tr(titleKey))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.tr(descriptionKey),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
