import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class TotalFixedAssetCard extends StatelessWidget {
  const TotalFixedAssetCard({super.key, required this.overviewFuture});

  final Future<DashboardOverviewSummary> overviewFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 92,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.tr('dashboard.totalFixedAsset'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<DashboardOverviewSummary>(
                    future: overviewFuture,
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final value = snapshot.data?.totalFixedAsset;

                      return Text(
                        isLoading
                            ? l10n.tr('common.loading')
                            : CurrencyFormatter.formatEuro(value),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Calibri',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              FilipIcons.fixedAsset,
              size: 50,
              color: Color(0xFFE5E5E5),
            ),
          ],
        ),
      ),
    );
  }
}
