import 'dart:async';
import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/router/app_route_observer.dart';
import 'package:filip_at_flutter/app/localization/app_language_scope.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/app_version/data/app_version_repository.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contracts_page.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/dashboard/presentation/widgets/advisor_info_card.dart';
import 'package:filip_at_flutter/features/dashboard/presentation/widgets/asset_liability_slider.dart';
import 'package:filip_at_flutter/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:filip_at_flutter/features/dashboard/presentation/widgets/distribution_chart_slider.dart';
import 'package:filip_at_flutter/features/dashboard/presentation/widgets/total_fixed_asset_card.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/explorer/presentation/filip_explorer_page.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/presentation/notifications_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/profile/gdpr_consent_flow.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/features/profile/presentation/profile_page.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/real_estate_page.dart';
import 'package:filip_at_flutter/features/settings/presentation/settings_page.dart';
import 'package:filip_at_flutter/features/about/presentation/about_page.dart';
import 'package:filip_at_flutter/features/support/presentation/support_page.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.config,
    required this.dashboardRepository,
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.authSessionController,
    required this.syncNotificationService,
    required this.householdController,
    required this.driveRepository,
    required this.userSessionCache,
    required this.profileRepository,
    required this.appVersionRepository,
    this.surveyAddressRepository,
  });

  final AppConfig config;
  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AuthSessionController authSessionController;
  final SyncNotificationService syncNotificationService;
  final HouseholdMemberFilterController householdController;
  final DriveRepository driveRepository;
  final UserSessionCache userSessionCache;
  final ProfileRepository profileRepository;
  final AppVersionRepository appVersionRepository;
  final SurveyAddressRepository? surveyAddressRepository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with RouteAware, WidgetsBindingObserver {
  // Futures only assigned after the sync notification arrives
  Future<DashboardOverviewSummary>? _overviewFuture;
  Future<DashboardInsightsData>? _insightsFuture;
  Future<Uri?>? _dfsInvestmentUriFuture;

  // These are independent of the sync cycle
  late Future<UserProfile?> _userProfileFuture;
  late Future<int> _unreadNotificationsFuture;

  late final PageController _summaryCardsController;
  late final PageController _distributionCardsController;
  late StreamSubscription<Map<String, dynamic>> _assetSyncSubscription;
  late StreamSubscription<Map<String, dynamic>> _syncCustomerContractSubscription;
  StreamSubscription<Map<String, dynamic>>? _gdprSyncSubscription;

  int _activeSummaryCardIndex = 0;
  int _activeDistributionCardIndex = 0;
  bool _isOpeningInvestmentPortal = false;
  bool _isSyncPending = true;
  bool _shouldAutoShowDashboardGdpr = false;
  bool _hasShownDashboardGdpr = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _summaryCardsController = PageController(viewportFraction: 0.92);
    _distributionCardsController = PageController(viewportFraction: 0.88);
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _unreadNotificationsFuture = widget.notificationsRepository.fetchUnreadCount();

    _assetSyncSubscription = widget.syncNotificationService.assetCalculationSyncCompleted.stream.listen((_) {
      if (!mounted) return;
      setState(() => _onSyncCompleted());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('CONTRACT_SYNC_COMPLETED'))),
      );
    });

    _syncCustomerContractSubscription = widget.syncNotificationService.synccustomercontract.stream.listen((_) {
      if (!mounted) return;
      setState(() => _onSyncCompleted());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('CONTRACT_SYNC_COMPLETED'))),
      );
    });

    _gdprSyncSubscription = widget.syncNotificationService.gdprConsentSync.stream.listen((_) {
      _tryOpenDashboardGdpr();
    });
    unawaited(_prepareDashboardGdprFlow());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() => _triggerSyncFlow();

  @override
  void didPopNext() => _triggerSyncFlow();

  void _triggerSyncFlow() {
    setState(() {
      _isSyncPending = true;
      _overviewFuture = null;
      _insightsFuture = null;
      _dfsInvestmentUriFuture = null;
      _unreadNotificationsFuture = widget.notificationsRepository.fetchUnreadCount();
    });
    widget.dashboardRepository.triggerCalculateAsset().catchError((_) {});
    widget.dashboardRepository.triggerSyncCustomerAdditiveContract().catchError((_) {});
  }

  void _onSyncCompleted() {
    _isSyncPending = false;
    _overviewFuture = widget.dashboardRepository.fetchOverviewSummary();
    _insightsFuture = widget.dashboardRepository.fetchInsightsData();
    _dfsInvestmentUriFuture = widget.dashboardRepository.fetchDfsInvestmentUri();
    _unreadNotificationsFuture = widget.notificationsRepository.fetchUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _summaryCardsController.dispose();
    _distributionCardsController.dispose();
    _assetSyncSubscription.cancel();
    _syncCustomerContractSubscription.cancel();
    _gdprSyncSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAppVersion();
    }
  }

  Future<void> _checkAppVersion() async {
    final session = await widget.userSessionCache.resolve();
    if (!mounted) return;
    final status = await widget.appVersionRepository
        .checkAppVersion(session?.accessToken ?? '');
    if (!mounted) return;
    if (status == AppVersionStatus.maintenance) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/maintenance', (_) => false);
    } else if (status == AppVersionStatus.forceUpdate) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/force-update', (_) => false);
    }
  }

  Future<void> _prepareDashboardGdprFlow() async {
    final loginCount = await widget.authSessionController.getLoginCount();
    if (!mounted) return;
    _shouldAutoShowDashboardGdpr = loginCount <= 1;
  }

  Future<void> _tryOpenDashboardGdpr() async {
    if (!mounted || !_shouldAutoShowDashboardGdpr || _hasShownDashboardGdpr) {
      return;
    }
    _hasShownDashboardGdpr = true;
    await widget.householdController.ensureLoaded();
    if (!mounted) return;
    final showHouseholdOption =
        widget.householdController.householdMembers.length > 1;
    await GdprConsentFlow.open(
      context: context,
      repository: widget.profileRepository,
      showHouseholdOption: showHouseholdOption,
      syncNotificationService: widget.syncNotificationService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      drawer: AppSideDrawer(
        userProfileFuture: _userProfileFuture,
        dashboardRepository: widget.dashboardRepository,
        contractsRepository: widget.contractsRepository,
        notificationsRepository: widget.notificationsRepository,
        authSessionController: widget.authSessionController,
        appVersion: widget.config.appVersion,
        syncNotificationService: widget.syncNotificationService,
        householdController: widget.householdController,
        driveRepository: widget.driveRepository,
        userSessionCache: widget.userSessionCache,
        profileRepository: widget.profileRepository,
        surveyAddressRepository: widget.surveyAddressRepository,
      ),
      body: Builder(
        builder: (innerContext) => SafeArea(
          child: Column(
            children: [
              FutureBuilder<int>(
                future: _unreadNotificationsFuture,
                builder: (context, snapshot) {
                  return DashboardTopBar(
                    config: widget.config,
                    onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                    onNotificationTap: () => _openNotifications(),
                    showNotificationBadge: (snapshot.data ?? 0) > 0,
                  );
                },
              ),
              Expanded(
                child: _isSyncPending
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryRed,
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 92),
                        child: Column(
                          children: [
                            TotalFixedAssetCard(overviewFuture: _overviewFuture!),
                            const SizedBox(height: 14),
                            AssetLiabilitySlider(
                              overviewFuture: _overviewFuture!,
                              controller: _summaryCardsController,
                              activeIndex: _activeSummaryCardIndex,
                              onInvestmentTap: _handleInvestmentTap,
                              onPageChanged: (index) {
                                setState(() {
                                  _activeSummaryCardIndex = index;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            DistributionChartSlider(
                              insightsFuture: _insightsFuture!,
                              controller: _distributionCardsController,
                              activeIndex: _activeDistributionCardIndex,
                              onPageChanged: (index) {
                                setState(() {
                                  _activeDistributionCardIndex = index;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            AdvisorInfoCard(
                              insightsFuture: _insightsFuture!,
                              onChatTap: () => _openPage(context, const ChatPage()),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppNavTab.dashboard,
        onDashboardTap: () {},
        onHomeTap: () => _openPage(
          context,
          FilipExplorerPage(
            dashboardRepository: widget.dashboardRepository,
            contractsRepository: widget.contractsRepository,
            notificationsRepository: widget.notificationsRepository,
            authSessionController: widget.authSessionController,
            appVersion: widget.config.appVersion,
            syncNotificationService: widget.syncNotificationService,
            householdController: widget.householdController,
            driveRepository: widget.driveRepository,
            userSessionCache: widget.userSessionCache,
            profileRepository: widget.profileRepository,
            surveyAddressRepository: widget.surveyAddressRepository,
          ),
        ),
        onContractsTap: () => _openPage(
          context,
          ContractsPage(
            contractsRepository: widget.contractsRepository,
            dashboardRepository: widget.dashboardRepository,
            notificationsRepository: widget.notificationsRepository,
            authSessionController: widget.authSessionController,
            appVersion: widget.config.appVersion,
            syncNotificationService: widget.syncNotificationService,
            householdController: widget.householdController,
            driveRepository: widget.driveRepository,
            userSessionCache: widget.userSessionCache,
            profileRepository: widget.profileRepository,
            surveyAddressRepository: widget.surveyAddressRepository,
          ),
        ),
        onRealEstateTap: () => _openPage(context, const RealEstatePage()),
        onMessagesTap: () => _openPage(context, const ChatPage()),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
          dashboardRepository: widget.dashboardRepository,
          contractsRepository: widget.contractsRepository,
          notificationsRepository: widget.notificationsRepository,
          authSessionController: widget.authSessionController,
          appVersion: widget.config.appVersion,
          syncNotificationService: widget.syncNotificationService,
          householdController: widget.householdController,
          driveRepository: widget.driveRepository,
          userSessionCache: widget.userSessionCache,
          profileRepository: widget.profileRepository,
          surveyAddressRepository: widget.surveyAddressRepository,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _unreadNotificationsFuture = widget.notificationsRepository.fetchUnreadCount();
    });
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _handleInvestmentTap() async {
    if (_isOpeningInvestmentPortal) {
      return;
    }

    setState(() {
      _isOpeningInvestmentPortal = true;
    });

    try {
      final uri = await _dfsInvestmentUriFuture;
      if (uri == null) {
        if (!mounted) {
          return;
        }
        _showDashboardMessage(
          context.l10n.tr('tns.unknownError'),
        );
        _dfsInvestmentUriFuture = widget.dashboardRepository
            .fetchDfsInvestmentUri();
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showDashboardMessage(
          context.l10n.tr('tns.unknownError'),
        );
        _dfsInvestmentUriFuture = widget.dashboardRepository
            .fetchDfsInvestmentUri();
      }
    } catch (_) {
      _dfsInvestmentUriFuture = widget.dashboardRepository
          .fetchDfsInvestmentUri();
      if (mounted) {
        _showDashboardMessage(
          context.l10n.tr('tns.unknownError'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningInvestmentPortal = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await widget.authSessionController.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _showDashboardMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}


class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.userProfileFuture,
    required this.onProfileTap,
    required this.onPreferencesTap,
    required this.onHouseholdTap,
    required this.onSurveyTap,
    required this.onSupportTap,
    required this.onAboutTap,
    required this.onLogoutTap,
  });

  final Future<UserProfile?> userProfileFuture;
  final VoidCallback onProfileTap;
  final VoidCallback onPreferencesTap;
  final VoidCallback onHouseholdTap;
  final VoidCallback onSurveyTap;
  final VoidCallback onSupportTap;
  final VoidCallback onAboutTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageController = AppLanguageScope.of(context);
    final isEnglish = languageController.languageCode == 'en';

    return Drawer(
      width: 286,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Red header with user info and overlapping avatar ──
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

          // ── Menu items ──
          _DrawerItem(
            icon: FilipIcons.personOutline,
            label: l10n.tr('tns.myAccount'),
            onTap: onProfileTap,
          ),
          _DrawerItem(
            icon: FilipIcons.preferences,
            label: l10n.tr('tns.preferences'),
            onTap: onPreferencesTap,
          ),
          _DrawerItem(
            icon: FilipIcons.household,
            label: l10n.tr('tns.household'),
            onTap: onHouseholdTap,
          ),
          _DrawerItem(
            icon: FilipIcons.survey,
            label: l10n.tr('tns.SURVEY'),
            onTap: onSurveyTap,
          ),
          _DrawerItem(
            icon: FilipIcons.support,
            label: l10n.tr('tns.support'),
            onTap: onSupportTap,
          ),
          _DrawerItem(
            icon: FilipIcons.about,
            label: l10n.tr('tns.about'),
            onTap: onAboutTap,
          ),

          const Spacer(),

          // ── LOG OUT button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onLogoutTap,
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

          // ── Divider ──
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 4),

          // ── Language toggle ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(
                  FilipIcons.global,
                  size: 20,
                  color: const Color(0xFF7E7E7E),
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

          // ── Legal links ──
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
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
                  onPressed: () {},
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
