import 'dart:math' as math;

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppNavTab { dashboard, contracts, home, realEstate, message }

class AppBottomNav extends StatelessWidget {
  static const double _outerCircleSize = _innerCircleSize;
  static const double _innerCircleSize = 74;
  static const double _centerGapWidth = 112;

  static const double _barBaseHeight = 78;
  static const double _barCornerRadius = 26;
  static const double _barHorizontalInset = 0;
  static const double _notchMargin = 0;
  static const double _barElevation = 18;
  static const double _centerCircleLift = 8;

  const AppBottomNav({
    super.key,
    this.activeTab,
    required this.onDashboardTap,
    required this.onHomeTap,
    required this.onContractsTap,
    required this.onRealEstateTap,
    required this.onMessagesTap,
  });

  final AppNavTab? activeTab;
  final VoidCallback onDashboardTap;
  final VoidCallback onHomeTap;
  final VoidCallback onContractsTap;
  final VoidCallback onRealEstateTap;
  final VoidCallback onMessagesTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isHomeActive = activeTab == AppNavTab.home;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barHeight = _barBaseHeight + bottomInset;

    return SizedBox(
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: _barHorizontalInset,
            right: _barHorizontalInset,
            bottom: 0,
            child: PhysicalShape(
              clipBehavior: Clip.antiAlias,
              clipper: _NotchedRoundedRectClipper(
                cornerRadius: _barCornerRadius,
                notchRadius: (_outerCircleSize / 2) + _notchMargin,
              ),
              elevation: _barElevation,
              color: Colors.white,
              shadowColor: const Color(0x22000000),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  height: barHeight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: _NavItem(
                                  assetPath:
                                      'assets/images/dashboard/dashboard_duo.png',
                                  activeAssetPath:
                                      'assets/images/dashboard/dashboard_duo_select.png',
                                  label: l10n.tr('dashboard.navDashboard'),
                                  isActive: activeTab == AppNavTab.dashboard,
                                  onTap: onDashboardTap,
                                ),
                              ),
                              Expanded(
                                child: _NavItem(
                                  assetPath:
                                      'assets/images/dashboard/contracts_duo.png',
                                  activeAssetPath:
                                      'assets/images/dashboard/contracts_duo_select.png',
                                  label: l10n.tr('dashboard.navContracts'),
                                  isActive: activeTab == AppNavTab.contracts,
                                  onTap: onContractsTap,
                                ),
                              ),
                              const SizedBox(width: _centerGapWidth),
                              Expanded(
                                child: _NavItem(
                                  assetPath:
                                      'assets/images/dashboard/real_estate_duo.png',
                                  activeAssetPath:
                                      'assets/images/dashboard/real_estate_duo_select.png',
                                  label: l10n.tr('dashboard.navRealEstate'),
                                  isActive: activeTab == AppNavTab.realEstate,
                                  onTap: onRealEstateTap,
                                ),
                              ),
                              Expanded(
                                child: _NavItem(
                                  assetPath:
                                      'assets/images/dashboard/message_duo.png',
                                  activeAssetPath:
                                      'assets/images/dashboard/message_duo_select.png',
                                  label: l10n.tr('dashboard.navMessage'),
                                  isActive: activeTab == AppNavTab.message,
                                  onTap: onMessagesTap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: _centerGapWidth,
                          height: double.infinity,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (_) => onHomeTap(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -(_outerCircleSize / 2) - _centerCircleLift,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => onHomeTap(),
              child: Container(
                width: _outerCircleSize,
                height: _outerCircleSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: _innerCircleSize,
                    height: _innerCircleSize,
                    decoration: BoxDecoration(
                      color: isHomeActive ? AppColors.primaryRed : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        isHomeActive
                            ? 'assets/images/dashboard/filip_white.png'
                            : 'assets/images/dashboard/filipred.png',
                        width: 42,
                        height: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchedRoundedRectClipper extends CustomClipper<Path> {
  const _NotchedRoundedRectClipper({
    required this.cornerRadius,
    required this.notchRadius,
  });

  final double cornerRadius;
  final double notchRadius;

  @override
  Path getClip(Size size) {
    final hostRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final hostPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(hostRect, Radius.circular(cornerRadius)),
      );

    final guestRect = Rect.fromCircle(
      center: Offset(size.width / 2, hostRect.top),
      radius: notchRadius,
    );

    final rectPath = Path()..addRect(hostRect);
    final notchedRectPath = const _FilipNotchedRectangle().getOuterPath(
      hostRect,
      guestRect,
    );
    final removedArea = Path.combine(
      PathOperation.difference,
      rectPath,
      notchedRectPath,
    );

    return Path.combine(PathOperation.difference, hostPath, removedArea);
  }

  @override
  bool shouldReclip(covariant _NotchedRoundedRectClipper oldClipper) {
    return cornerRadius != oldClipper.cornerRadius ||
        notchRadius != oldClipper.notchRadius;
  }
}

class _FilipNotchedRectangle extends NotchedShape {
  const _FilipNotchedRectangle();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRect(host);
    }

    final double r = guest.width / 2.0;
    final Radius notchRadius = Radius.circular(r);

    // Bigger values produce a wider, softer notch that matches the NativeScript
    // design more closely than the default CircularNotchedRectangle.
    const double s1 = 21.0;
    const double s2 = 6.0;

    final double a = -r - s2;
    final double b = host.top - guest.center.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    final p = List<Offset>.filled(6, Offset.zero);

    p[0] = Offset(a - s1, b);
    p[1] = Offset(a, b);
    final cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);
    p[3] = Offset(-p[2].dx, p[2].dy);
    p[4] = Offset(-p[1].dx, p[1].dy);
    p[5] = Offset(-p[0].dx, p[0].dy);

    for (var i = 0; i < p.length; i += 1) {
      p[i] += guest.center;
    }

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(p[3], radius: notchRadius, clockwise: false)
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.assetPath,
    required this.activeAssetPath,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String assetPath;
  final String activeAssetPath;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isActive ? activeAssetPath : assetPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: isActive
                    ? AppColors.primaryRed
                    : const Color(0xFF808285),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
