import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contracts_page.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/explorer/presentation/filip_explorer_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/presentation/notifications_page.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/real_estate/application/observation_controller.dart';
import 'package:filip_at_flutter/features/real_estate/application/search_query_controller.dart';
import 'package:filip_at_flutter/features/real_estate/application/valuation_controller.dart';
import 'package:filip_at_flutter/features/real_estate/data/real_estate_repository.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/observation_tab.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/search_tab.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/valuation_tab.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/widgets/real_estate_top_tab_bar.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/shared/widgets/app_page_header.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';

class RealEstatePage extends StatefulWidget {
  const RealEstatePage({
    super.key,
    required this.repository,
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
    this.surveyAddressRepository,
  });

  final RealEstateRepository repository;
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
  final SurveyAddressRepository? surveyAddressRepository;

  @override
  State<RealEstatePage> createState() => _RealEstatePageState();
}

class _RealEstatePageState extends State<RealEstatePage> {
  late final ObservationController _observationCtrl;
  late final ValuationController _valuationCtrl;
  late final SearchQueryController _searchCtrl;
  late final Future<UserProfile?> _userProfileFuture;
  late Future<int> _unreadNotificationsFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _observationCtrl = ObservationController(repository: widget.repository);
    _valuationCtrl = ValuationController(repository: widget.repository);
    _searchCtrl = SearchQueryController(repository: widget.repository);
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _unreadNotificationsFuture =
        widget.notificationsRepository.fetchUnreadCount();
  }

  @override
  void dispose() {
    _observationCtrl.dispose();
    _valuationCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
          dashboardRepository: widget.dashboardRepository,
          contractsRepository: widget.contractsRepository,
          notificationsRepository: widget.notificationsRepository,
          authSessionController: widget.authSessionController,
          appVersion: widget.appVersion,
          syncNotificationService: widget.syncNotificationService,
          householdController: widget.householdController,
          driveRepository: widget.driveRepository,
          userSessionCache: widget.userSessionCache,
          realEstateRepository: widget.repository,
          profileRepository: widget.profileRepository,
          surveyAddressRepository: widget.surveyAddressRepository,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _unreadNotificationsFuture =
          widget.notificationsRepository.fetchUnreadCount();
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      drawer: AppSideDrawer(
        userProfileFuture: _userProfileFuture,
        dashboardRepository: widget.dashboardRepository,
        contractsRepository: widget.contractsRepository,
        notificationsRepository: widget.notificationsRepository,
        authSessionController: widget.authSessionController,
        appVersion: widget.appVersion,
        syncNotificationService: widget.syncNotificationService,
        householdController: widget.householdController,
        driveRepository: widget.driveRepository,
        userSessionCache: widget.userSessionCache,
        realEstateRepository: widget.repository,
        profileRepository: widget.profileRepository,
        surveyAddressRepository: widget.surveyAddressRepository,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (innerContext) => FutureBuilder<int>(
                future: _unreadNotificationsFuture,
                builder: (context, snapshot) {
                  return AppTopBar(
                    onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                    onNotificationTap: _openNotifications,
                    showBadge: (snapshot.data ?? 0) > 0,
                  );
                },
              ),
            ),
            AppPageHeader(title: l10n.tr('tns.myrealEstate')),
            RealEstateTopTabBar(
              selectedIndex: _selectedIndex,
              onTabSelected: (i) => setState(() => _selectedIndex = i),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  ObservationTab(
                    controller: _observationCtrl,
                    repository: widget.repository,
                  ),
                  ValuationTab(
                    controller: _valuationCtrl,
                    repository: widget.repository,
                  ),
                  SearchTab(
                    controller: _searchCtrl,
                    repository: widget.repository,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppNavTab.realEstate,
        onDashboardTap: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        onHomeTap: () {
          final navigator = Navigator.of(context);
          navigator.popUntil((route) => route.isFirst);
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => FilipExplorerPage(
                dashboardRepository: widget.dashboardRepository,
                contractsRepository: widget.contractsRepository,
                notificationsRepository: widget.notificationsRepository,
                authSessionController: widget.authSessionController,
                appVersion: widget.appVersion,
                syncNotificationService: widget.syncNotificationService,
                householdController: widget.householdController,
                driveRepository: widget.driveRepository,
                userSessionCache: widget.userSessionCache,
                realEstateRepository: widget.repository,
                profileRepository: widget.profileRepository,
                surveyAddressRepository: widget.surveyAddressRepository,
              ),
            ),
          );
        },
        onContractsTap: () => _openPage(
          ContractsPage(
            contractsRepository: widget.contractsRepository,
            dashboardRepository: widget.dashboardRepository,
            notificationsRepository: widget.notificationsRepository,
            authSessionController: widget.authSessionController,
            appVersion: widget.appVersion,
            syncNotificationService: widget.syncNotificationService,
            householdController: widget.householdController,
            driveRepository: widget.driveRepository,
            userSessionCache: widget.userSessionCache,
            realEstateRepository: widget.repository,
            profileRepository: widget.profileRepository,
            surveyAddressRepository: widget.surveyAddressRepository,
          ),
        ),
        onRealEstateTap: () {},
        onMessagesTap: () => _openPage(const ChatPage()),
      ),
    );
  }
}
