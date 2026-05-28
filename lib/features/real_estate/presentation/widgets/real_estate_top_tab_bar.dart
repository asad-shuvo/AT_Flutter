import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

const _iconFont = 'filip_at_iconpack_29022024';

const _tabs = [
  _TabDef(
    icon: IconData(0xE9D0, fontFamily: _iconFont),
    labelKey: 'tns.observationProperty',
  ),
  _TabDef(
    icon: IconData(0xEA05, fontFamily: _iconFont),
    labelKey: 'tns.valuationProperty',
  ),
  _TabDef(
    icon: IconData(0xE93C, fontFamily: _iconFont),
    labelKey: 'tns.searchProperty',
  ),
];

class RealEstateTopTabBar extends StatelessWidget {
  const RealEstateTopTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 64,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = i == selectedIndex;
            return Flexible(
              flex: isActive ? 4 : 2,
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                behavior: HitTestBehavior.opaque,
                child: isActive
                    ? _ActiveTab(
                        tab: tab,
                        label: l10n.tr(tab.labelKey).toUpperCase(),
                      )
                    : _InactiveTab(tab: tab),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.tab, required this.label});
  final _TabDef tab;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.screenBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 22, color: const Color(0xFF333333)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Calibri',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveTab extends StatelessWidget {
  const _InactiveTab({required this.tab});
  final _TabDef tab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F0F0),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(tab.icon, size: 20, color: const Color(0xFF999999)),
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef({required this.icon, required this.labelKey});
  final IconData icon;
  final String labelKey;
}
