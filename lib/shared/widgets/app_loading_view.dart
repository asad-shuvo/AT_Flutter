import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ?? context.l10n.tr('common.loading');

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(resolvedLabel),
        ],
      ),
    );
  }
}
