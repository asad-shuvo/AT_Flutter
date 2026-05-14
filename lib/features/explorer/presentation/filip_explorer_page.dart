import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contracts_page.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/documents/presentation/documents_page.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/notifications/presentation/notifications_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/real_estate_page.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/shared/widgets/app_page_header.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';

const String _filipIconFamily = 'filip_at_iconpack_29022024';

class FilipExplorerPage extends StatefulWidget {
  const FilipExplorerPage({
    super.key,
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
  State<FilipExplorerPage> createState() => _FilipExplorerPageState();
}

class _FilipExplorerPageState extends State<FilipExplorerPage> {
  late final Future<UserProfile?> _userProfileFuture;
  late Future<int> _unreadNotificationsFuture;
  late final PageController _sliderController;
  int _activeSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _unreadNotificationsFuture = widget.notificationsRepository
        .fetchUnreadCount();
    _sliderController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _sliderController.dispose();
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
          profileRepository: widget.profileRepository,
          surveyAddressRepository: widget.surveyAddressRepository,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _unreadNotificationsFuture = widget.notificationsRepository
          .fetchUnreadCount();
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _goToDashboardRoot() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final slides = <_ExplorerSlideData>[
      _ExplorerSlideData(
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
        icon: const IconData(0xE9E8, fontFamily: _filipIconFamily),
        onTap: () => _openPage(
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
            profileRepository: widget.profileRepository,
            surveyAddressRepository: widget.surveyAddressRepository,
          ),
        ),
      ),
      _ExplorerSlideData(
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
        icon: const IconData(0xE9B4, fontFamily: _filipIconFamily),
        onTap: () => _openPage(const RealEstatePage()),
      ),
      _ExplorerSlideData(
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
        icon: const IconData(0xE9C9, fontFamily: _filipIconFamily),
        onTap: () => _openPage(DocumentsPage(
          driveRepository: widget.driveRepository,
          householdController: widget.householdController,
          userSessionCache: widget.userSessionCache,
          dashboardRepository: widget.dashboardRepository,
          contractsRepository: widget.contractsRepository,
          notificationsRepository: widget.notificationsRepository,
          authSessionController: widget.authSessionController,
          appVersion: widget.appVersion,
          syncNotificationService: widget.syncNotificationService,
          profileRepository: widget.profileRepository,
        )),
      ),
      _ExplorerSlideData(
        title: l10n.tr('tns.title'),
        description: l10n.tr('tns.description'),
        icon: const IconData(0xEA03, fontFamily: _filipIconFamily),
        onTap: () => _openPage(const ChatPage()),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
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
                  return AppTopBar(
                    onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                    onNotificationTap: _openNotifications,
                    showBadge: (snapshot.data ?? 0) > 0,
                  );
                },
              ),
              AppPageHeader(title: l10n.tr('tns.explorerTitle')),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/dashboard/filip_explorer_background.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(15, 8, 15, 120),
                      child: Column(
                        children: [
                          _ExplorerTileGrid(
                            onMyRealEstateTap: () =>
                                _openPage(const RealEstatePage()),
                            onDriveTap: () => _openPage(DocumentsPage(
                              driveRepository: widget.driveRepository,
                              householdController: widget.householdController,
                              userSessionCache: widget.userSessionCache,
                              dashboardRepository: widget.dashboardRepository,
                              contractsRepository: widget.contractsRepository,
                              notificationsRepository: widget.notificationsRepository,
                              authSessionController: widget.authSessionController,
                              appVersion: widget.appVersion,
                              syncNotificationService: widget.syncNotificationService,
                              profileRepository: widget.profileRepository,
                            )),
                            onContractsTap: () => _openPage(
                              ContractsPage(
                                contractsRepository: widget.contractsRepository,
                                dashboardRepository: widget.dashboardRepository,
                                notificationsRepository:
                                    widget.notificationsRepository,
                                authSessionController:
                                    widget.authSessionController,
                                appVersion: widget.appVersion,
                                syncNotificationService:
                                    widget.syncNotificationService,
                                householdController: widget.householdController,
                                driveRepository: widget.driveRepository,
                                userSessionCache: widget.userSessionCache,
                                profileRepository: widget.profileRepository,
                                surveyAddressRepository: widget.surveyAddressRepository,
                              ),
                            ),
                            onMessageTap: () => _openPage(const ChatPage()),
                          ),
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              l10n.tr('tns.oneStopSolution'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFC77786),
                                height: 1.45,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _ExplorerSlider(
                            controller: _sliderController,
                            slides: slides,
                            activeIndex: _activeSlideIndex,
                            onPageChanged: (index) {
                              setState(() {
                                _activeSlideIndex = index;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppNavTab.home,
        onDashboardTap: _goToDashboardRoot,
        onHomeTap: () {},
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
            profileRepository: widget.profileRepository,
            surveyAddressRepository: widget.surveyAddressRepository,
          ),
        ),
        onRealEstateTap: () => _openPage(const RealEstatePage()),
        onMessagesTap: () => _openPage(const ChatPage()),
      ),
    );
  }
}

class _ExplorerTileGrid extends StatelessWidget {
  const _ExplorerTileGrid({
    required this.onMyRealEstateTap,
    required this.onDriveTap,
    required this.onContractsTap,
    required this.onMessageTap,
  });

  final VoidCallback onMyRealEstateTap;
  final VoidCallback onDriveTap;
  final VoidCallback onContractsTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ExplorerTile(
                label: l10n.tr('tns.myrealEstate'),
                icon: const IconData(0xE9B4, fontFamily: _filipIconFamily),
                onTap: onMyRealEstateTap,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ExplorerTile(
                label: l10n.tr('tns.tileDrive'),
                icon: const IconData(0xE9C9, fontFamily: _filipIconFamily),
                onTap: onDriveTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _ExplorerTile(
                label: l10n.tr('tns.contracts'),
                icon: const IconData(0xE9E8, fontFamily: _filipIconFamily),
                onTap: onContractsTap,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ExplorerTile(
                label: l10n.tr('tns.messageBottomNav'),
                icon: const IconData(0xEA03, fontFamily: _filipIconFamily),
                onTap: onMessageTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExplorerTile extends StatelessWidget {
  const _ExplorerTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8D8D8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRed, width: 1.2),
              ),
              child: Center(
                child: Icon(icon, size: 22, color: AppColors.primaryRed),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF797A76),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerSlider extends StatelessWidget {
  const _ExplorerSlider({
    required this.controller,
    required this.slides,
    required this.activeIndex,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<_ExplorerSlideData> slides;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _ExplorerSlideCard(data: slide),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final bool isActive = i == activeIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryRed
                    : const Color(0x33D82034),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ExplorerSlideCard extends StatelessWidget {
  const _ExplorerSlideCard({required this.data});

  final _ExplorerSlideData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD8D8D8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/dashboard/exp_card_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryRed,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          data.icon,
                          size: 22,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorerSlideData {
  const _ExplorerSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
}
