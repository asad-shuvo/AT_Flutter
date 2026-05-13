import 'package:filip_at_flutter/app/localization/app_language_scope.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/about/presentation/about_page.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/household/presentation/household_members_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/profile/presentation/profile_page.dart';
import 'package:filip_at_flutter/features/settings/presentation/settings_page.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
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
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.authSessionController,
    required this.appVersion,
    required this.syncNotificationService,
    required this.householdController,
    required this.driveRepository,
    required this.userSessionCache,
    this.profileRepository,
  });

  final Future<UserProfile?> userProfileFuture;
  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AuthSessionController authSessionController;
  final String appVersion;
  final SyncNotificationService syncNotificationService;
  final HouseholdMemberFilterController householdController;
  final DriveRepository driveRepository;
  final UserSessionCache userSessionCache;
  final ProfileRepository? profileRepository;
  static const String _legalUrl =
      'https://www.swisslife-select.at/home/footer/nutzungsbedingungen_filip.html';
  static const String _dataPrivacyUrl =
      'https://www.swisslife-select.at/home/footer/datenschutz.html';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageController = AppLanguageScope.of(context);
    final isEnglish = languageController.languageCode == 'en';

    return Drawer(
      width: 286,
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/dashboard/filip_white.png',
                              width: 25,
                              height: 25,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'FiLiP',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Calibri',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                    child: _DrawerAvatar(
                      profile: profile,
                      initials: initials,
                      avatarColor: avatarColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 52),
          AnimatedBuilder(
            animation: householdController,
            builder: (context, _) {
              final hasHouseholdMembers =
                  householdController.householdMembers.length > 1;
              final hasBusinessMembers =
                  householdController.businessMembers.isNotEmpty;
              return Column(
                children: [
                  _DrawerItem(
                    icon: FilipIcons.personOutline,
                    label: l10n.tr('dashboard.drawerAccount'),
                    onTap: () {
                      final repository = profileRepository;
                      if (repository == null) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Account page is unavailable here.'),
                            ),
                          );
                        return;
                      }
                      _openPage(
                        context,
                        ProfilePage(
                          dashboardRepository: dashboardRepository,
                          authSessionController: authSessionController,
                          profileRepository: repository,
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: FilipIcons.preferences,
                    label: l10n.tr('dashboard.drawerPreferences'),
                    onTap: () => _openPage(
                      context,
                      SettingsPage(
                        authSessionController: authSessionController,
                      ),
                    ),
                  ),
                  if (hasHouseholdMembers)
                    _DrawerItem(
                      icon: FilipIcons.household,
                      label: l10n.tr('dashboard.drawerHousehold'),
                      onTap: () => _openPage(
                        context,
                        HouseholdMembersPage(
                          dashboardRepository: dashboardRepository,
                          contractsRepository: contractsRepository,
                          notificationsRepository: notificationsRepository,
                          authSessionController: authSessionController,
                          appVersion: appVersion,
                          syncNotificationService: syncNotificationService,
                          householdController: householdController,
                          isBusiness: false,
                          driveRepository: driveRepository,
                          userSessionCache: userSessionCache,
                          profileRepository: profileRepository,
                        ),
                      ),
                    ),
                  if (hasBusinessMembers)
                    _DrawerItem(
                      icon: FilipIcons.business,
                      label: l10n.tr('tns.business').toUpperCase(),
                      onTap: () => _openPage(
                        context,
                        HouseholdMembersPage(
                          dashboardRepository: dashboardRepository,
                          contractsRepository: contractsRepository,
                          notificationsRepository: notificationsRepository,
                          authSessionController: authSessionController,
                          appVersion: appVersion,
                          syncNotificationService: syncNotificationService,
                          householdController: householdController,
                          isBusiness: true,
                          driveRepository: driveRepository,
                          userSessionCache: userSessionCache,
                          profileRepository: profileRepository,
                        ),
                      ),
                    ),
                  _DrawerItem(
                    icon: FilipIcons.survey,
                    label: l10n.tr('dashboard.drawerSurvey'),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _DrawerItem(
                    icon: FilipIcons.support,
                    label: l10n.tr('dashboard.drawerSupport'),
                    onTap: () => _openPage(context, const SupportPage()),
                  ),
                  _DrawerItem(
                    icon: FilipIcons.about,
                    label: l10n.tr('dashboard.drawerAbout'),
                    onTap: () =>
                        _openPage(context, AboutPage(appVersion: appVersion)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: Text(
                  l10n.tr('dashboard.drawerLogout'),
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(
                  FilipIcons.global,
                  size: 20,
                  color: Color(0xFF7E7E7E),
                ),
                const SizedBox(width: 10),
                Text(
                  isEnglish
                      ? l10n.tr('en').toUpperCase()
                      : l10n.tr('de').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 14,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isEnglish,
                  onChanged: (value) {
                    languageController.setLanguageCode(value ? 'en' : 'de');
                  },
                  activeThumbColor: AppColors.primaryRed,
                  inactiveThumbColor: const Color(0xFFBDBDBD),
                  inactiveTrackColor: const Color(0xFFE0E0E0),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Image.asset(
              'assets/images/login/swisslife_logo.png',
              height: 54,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _launchUrl(_legalUrl),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.tr('dashboard.drawerLegal'),
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
                  onPressed: () => _launchUrl(_dataPrivacyUrl),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.tr('dashboard.drawerDataPrivacy'),
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
    await performLogout(context, authSessionController: authSessionController);
  }
}

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar({
    required this.profile,
    required this.initials,
    required this.avatarColor,
  });

  final UserProfile? profile;
  final String initials;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Color(0xFF2D2D2D),
      fontFamily: 'Calibri',
      fontSize: 30,
      fontWeight: FontWeight.w600,
    );

    final imageUrl = profile?.resolvedProfileImageUrl;
    if (imageUrl != null) {
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: avatarColor,
              alignment: Alignment.center,
              child: Text(initials, style: textStyle),
            );
          },
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials, style: textStyle),
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
