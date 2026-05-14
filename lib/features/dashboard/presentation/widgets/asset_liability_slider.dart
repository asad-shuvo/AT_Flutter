import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class AssetLiabilitySlider extends StatelessWidget {
  const AssetLiabilitySlider({
    super.key,
    required this.overviewFuture,
    required this.controller,
    required this.activeIndex,
    required this.onInvestmentTap,
    required this.onPageChanged,
  });

  final Future<DashboardOverviewSummary> overviewFuture;
  final PageController controller;
  final int activeIndex;
  final VoidCallback onInvestmentTap;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<DashboardOverviewSummary>(
      future: overviewFuture,
      builder: (context, snapshot) {
        final cards = <_SliderCardData>[
          _SliderCardData(
            title: l10n.tr('tns.SLSInvestment'),
            value: snapshot.data?.totalInvestment,
            icon: FilipIcons.investment,
            showChevron: true,
            onTap: onInvestmentTap,
          ),
          _SliderCardData(
            title: l10n.tr('tns.totalMonthlyPremium'),
            value: snapshot.data?.totalMonthlyPremium,
            icon: FilipIcons.premium,
          ),
          _SliderCardData(
            title: l10n.tr('tns.totalLiabilities'),
            value: snapshot.data?.totalLiabilities,
            icon: FilipIcons.liabilities,
          ),
        ];

        return Column(
          children: [
            SizedBox(
              height: 92,
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                padEnds: false,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == cards.length - 1 ? 0 : 12,
                    ),
                    child: _SummarySliderCard(
                      title: card.title,
                      value: card.value,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                      icon: card.icon,
                      onTap: card.onTap,
                      showChevron: card.showChevron,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                cards.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: index == activeIndex
                        ? AppColors.primaryRed
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummarySliderCard extends StatelessWidget {
  const _SummarySliderCard({
    required this.title,
    required this.value,
    required this.isLoading,
    required this.icon,
    required this.onTap,
    required this.showChevron,
  });

  final String title;
  final double? value;
  final bool isLoading;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isLoading
                      ? context.l10n.tr('tns.loading')
                      : CurrencyFormatter.formatEuro(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Calibri',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.iconLight, size: 50),
              if (showChevron) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryRed,
                  size: 22,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class _SliderCardData {
  const _SliderCardData({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.showChevron = false,
  });

  final String title;
  final double? value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showChevron;
}
