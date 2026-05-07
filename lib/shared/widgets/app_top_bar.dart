import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.onMenuTap,
    this.onNotificationTap,
    this.showBadge = true,
    this.notificationIconColor = const Color(0xFF808080),
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final bool showBadge;
  final Color notificationIconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
              behavior: HitTestBehavior.opaque,
              child: const Center(
                child: Icon(FilipIcons.menu, size: 22, color: Color(0xFF808080)),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/login/splash_logo.png',
                width: 80,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: onNotificationTap ?? () {},
              behavior: HitTestBehavior.opaque,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(
                      FilipIcons.notifications,
                      size: 24,
                      color: notificationIconColor,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
