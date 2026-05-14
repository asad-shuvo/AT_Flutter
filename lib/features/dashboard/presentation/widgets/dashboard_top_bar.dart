import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/widgets/app_page_header.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.config,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.showNotificationBadge,
  });

  final AppConfig config;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final bool showNotificationBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          onMenuTap: onMenuTap,
          onNotificationTap: onNotificationTap,
          showBadge: showNotificationBadge,
        ),
        AppPageHeader(title: context.l10n.tr('tns.myFinancialSummary')),
      ],
    );
  }
}
