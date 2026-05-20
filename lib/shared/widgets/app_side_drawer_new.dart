import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/about/presentation/about_page.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/profile/presentation/profile_page.dart';
import 'package:filip_at_flutter/features/settings/presentation/settings_page.dart';
import 'package:filip_at_flutter/features/support/presentation/support_page.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/utils/logout_utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({
    super.key,
    required this.userProfileFuture,
    required this.dashboardRepository,
    required this.authSessionController,
    required this.appVersion,
  });

  final Future<UserProfile?> userProfileFuture;
  final DashboardRepository dashboardRepository;
  final AuthSessionController authSessionController;
  final String appVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Drawer(
      width: 286,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          FutureBuilder<UserProfile?>(
            future: userProfileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final initials = profile?.initials ?? '';
              final avatarColor = Color(
                profile?.avatarColorValue ?? 0xFF3BAF8E,
              );

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 44),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (profile != null && profile.displayName.isNotEmpty)
                          Text(
                            profile.displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Calibri',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (profile != null && profile.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFEFB8BF),
                              fontFamily: 'Calibri',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF2D2D2D),
                            fontFamily: 'Calibri',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 52),
          _DrawerItem(
            icon: FilipIcons.personOutline,
            label: l10n.tr('tns.myAccount'),
            onTap: () => _openPage(
              context,
              ProfilePage(
                dashboardRepository: dashboardRepository,
                authSessionController: authSessionController,
              ),
            ),
          ),
          _DrawerItem(
            icon: FilipIcons.preferences,
            label: l10n.tr('tns.preferences'),
            onTap: () => _openPage(
              context,
              SettingsPage(authSessionController: authSessionController, profileRepository: null),
            ),
          ),
          _DrawerItem(
            icon: FilipIcons.household,
            label: l10n.tr('tns.household'),
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerItem(
            icon: FilipIcons.survey,
            label: l10n.tr('tns.SURVEY'),
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerItem(
            icon: FilipIcons.support,
            label: l10n.tr('tns.support'),
            onTap: () => _openPage(context, const SupportPage()),
          ),
          _DrawerItem(
            icon: FilipIcons.about,
            label: l10n.tr('tns.about'),
            onTap: () => _openPage(context, AboutPage(appVersion: appVersion)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: Text(
                  l10n.tr('tns.logout'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Image.asset(
              'assets/images/login/swisslife_logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _launchUrl('https://www.filip.at/legal'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.tr('tns.legal'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '|',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                ),
                TextButton(
                  onPressed: () => _launchUrl('https://www.filip.at/dataprivacy'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.tr('tns.dataPrivacy'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop();
    await performLogout(
      context,
      authSessionController: authSessionController,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF7E7E7E)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
