import 'dart:math' as math;

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class DistributionChartSlider extends StatelessWidget {
  const DistributionChartSlider({
    super.key,
    required this.insightsFuture,
    required this.controller,
    required this.activeIndex,
    required this.onPageChanged,
  });

  final Future<DashboardInsightsData> insightsFuture;
  final PageController controller;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardInsightsData>(
      future: insightsFuture,
      builder: (context, snapshot) {
        final cards =
            snapshot.data?.distributionCards ??
            const <DashboardDistributionCardData>[];
        if (cards.isEmpty &&
            snapshot.connectionState != ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final itemCount = cards.isEmpty ? 3 : cards.length;

        return Column(
          children: [
            SizedBox(
              height: 566,
              child: PageView.builder(
                controller: controller,
                onPageChanged: onPageChanged,
                padEnds: false,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final card = cards.isEmpty
                      ? _loadingCard(index)
                      : cards[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == itemCount - 1 ? 0 : 12,
                    ),
                    child: _DistributionSliderCard(
                      card: card,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                itemCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: index == activeIndex
                        ? AppColors.primaryRed
                        : const Color(0xFFCFCFCF),
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

  DashboardDistributionCardData _loadingCard(int index) {
    const cards = <DashboardDistributionCardData>[
      DashboardDistributionCardData(
        cardTitle: 'dashboard.totalInvestment',
        chartTitle: 'dashboard.currentInvestmentDistribution',
        totalValue: 0,
        totalValueColorValue: 0xFF15847B,
        chartBackgroundColorValue: 0xFFE3F0EF,
        iconCodePoint: 0xEA15,
        segments: <DashboardDistributionSegment>[],
      ),
      DashboardDistributionCardData(
        cardTitle: 'dashboard.monthlyPremium',
        chartTitle: 'dashboard.monthlyPremiumDistribution',
        totalValue: 0,
        totalValueColorValue: 0xFFB4495E,
        chartBackgroundColorValue: 0xFFFFF5F6,
        iconCodePoint: 0xE956,
        segments: <DashboardDistributionSegment>[],
      ),
      DashboardDistributionCardData(
        cardTitle: 'dashboard.monthlyPayment',
        chartTitle: 'dashboard.monthlyPensionDistribution',
        totalValue: 0,
        totalValueColorValue: 0xFF607E46,
        chartBackgroundColorValue: 0xFFECF0E9,
        iconCodePoint: 0xE948,
        segments: <DashboardDistributionSegment>[],
      ),
    ];

    return cards[index];
  }
}

class _DistributionSliderCard extends StatefulWidget {
  const _DistributionSliderCard({required this.card, required this.isLoading});

  final DashboardDistributionCardData card;
  final bool isLoading;

  @override
  State<_DistributionSliderCard> createState() =>
      _DistributionSliderCardState();
}

// ignore: constant_identifier_names
const _kFlipDuration = Duration(milliseconds: 300);

class _DistributionSliderCardState extends State<_DistributionSliderCard>
    with SingleTickerProviderStateMixin {
  bool _showList = false;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: _kFlipDuration,
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    );
    _flipAnimation.addListener(() {
      final shouldShowList = _flipAnimation.value >= 0.5;
      if (shouldShowList != _showList) {
        setState(() => _showList = shouldShowList);
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading || widget.card.segments.isEmpty) return;
    if (!_showList) {
      _flipController.forward(from: 0);
    } else {
      _flipController.reverse(from: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color(widget.card.chartBackgroundColorValue);
    final totalValueColor = Color(widget.card.totalValueColorValue);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.resolve(widget.card.cardTitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.4,
                          color: Color(0xFF808080),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.isLoading
                            ? context.l10n.tr('common.loading')
                            : CurrencyFormatter.formatEuro(
                                widget.card.totalValue,
                              ),
                        style: TextStyle(
                          color: totalValueColor,
                          fontFamily: 'Calibri',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    _iconForCodePoint(widget.card.iconCodePoint),
                    color: AppColors.iconLight,
                    size: 52,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _showList ? AppColors.white : backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: widget.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryRed,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, _) {
                          final v = _flipAnimation.value;
                          final angle = v < 0.5
                              ? v * math.pi
                              : (v - 1) * math.pi;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(angle),
                            child: _showList
                                ? _buildListView()
                                : _buildChartView(),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.resolve(widget.card.chartTitle),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 232,
              height: 232,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  segments: widget.card.segments,
                  emptyRingColor: Color(widget.card.chartBackgroundColorValue),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.card.segments.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              context.l10n.tr('dashboard.noDataAdded'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF9D9D9D)),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.card.segments
                .map(
                  (segment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Color(segment.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.resolve(segment.label),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.resolve(widget.card.chartTitle),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Calibri',
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.card.segments.map((segment) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.resolve(segment.label),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Calibri',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      CurrencyFormatter.formatEuro(segment.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Calibri',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconForCodePoint(int codePoint) {
    switch (codePoint) {
      case 0xEA15:
        return FilipIcons.investment;
      case 0xE956:
        return FilipIcons.insurance;
      case 0xE948:
        return FilipIcons.pension;
      default:
        return FilipIcons.investment;
    }
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.segments,
    required this.emptyRingColor,
  });

  final List<DashboardDistributionSegment> segments;
  final Color emptyRingColor;

  @override
  void paint(Canvas canvas, Size size) {
    final halfSize = math.min(size.width, size.height) / 2;
    final strokeWidth = halfSize * 0.18;
    final radius = halfSize * 0.82;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = emptyRingColor;

    canvas.drawArc(rect, 0, math.pi * 2, false, basePaint);

    if (segments.isEmpty) {
      return;
    }

    // Clip negatives to 0 for arc drawing (NativeScript's positiveValueOnly).
    // The original values (including negatives) are preserved in segments for
    // the list view display.
    final positiveValues = segments
        .map((s) => math.max(0.0, s.value))
        .toList();
    final total = positiveValues.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) {
      return;
    }

    var startAngle = -math.pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final sweepAngle = (positiveValues[i] / total) * math.pi * 2;
      if (sweepAngle <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = Color(segments[i].colorValue);

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.emptyRingColor != emptyRingColor;
  }
}
