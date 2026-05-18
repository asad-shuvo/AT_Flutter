import 'dart:async';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';
import 'package:filip_at_flutter/features/notifications/presentation/notifications_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/real_estate_page.dart';
import 'package:filip_at_flutter/features/explorer/presentation/filip_explorer_page.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_delete_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_investment_tab.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_non_life_insurance_tab.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_retirement_tab.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_loan_tab.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/shared/widgets/app_page_header.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
import 'package:filip_at_flutter/shared/widgets/contracts_household_member_filter.dart';
import 'package:flutter/material.dart';

class ContractsPage extends StatefulWidget {
  const ContractsPage({
    super.key,
    required this.contractsRepository,
    required this.dashboardRepository,
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

  final ContractsRepository contractsRepository;
  final DashboardRepository dashboardRepository;
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
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  int _activeContractTab = 0;
  final Set<int> _syncUnlockedTabs = <int>{};
  late final Future<UserProfile?> _userProfileFuture;
  late Future<int> _unreadNotificationsFuture;
  late StreamSubscription<Map<String, dynamic>> _contractSyncSubscription;

  HouseholdMemberFilterController get _householdController =>
      widget.householdController;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _unreadNotificationsFuture =
        widget.notificationsRepository.fetchUnreadCount();

    // Bootstrap loads household data on auth + notifications.
    // Only load here if somehow not yet initialized (e.g. deep-link before auth listener fires).
    if (_householdController.isInitialized) {
      _householdController.resetToMeDefault();
    } else {
      unawaited(
        _householdController.ensureLoaded().then((_) {
          if (!mounted) return;
          _householdController.resetToMeDefault();
        }),
      );
    }
    unawaited(widget.contractsRepository.prewarmAddContractLookups());

    _contractSyncSubscription =
        widget.syncNotificationService.contractSyncCompleted.stream.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _syncUnlockedTabs.add(_activeContractTab);
        });
        if (_activeContractTab != 0 &&
            !_shouldSkipContractSyncSnackbar(event)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.tr('CONTRACT_SYNC_COMPLETED'))),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _contractSyncSubscription.cancel();
    super.dispose();
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  bool _shouldSkipContractSyncSnackbar(Map<String, dynamic> event) {
    return readBoolLike(event['SkipContractSync']) ?? false;
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
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _unreadNotificationsFuture = widget.notificationsRepository
          .fetchUnreadCount();
    });
  }

  Future<void> _openHouseholdSheet() async {
    if (_householdController.isLoading ||
        !_householdController.shouldShowFilter) {
      return;
    }

    final result = await showContractsHouseholdFilterSheet(
      context,
      initialMode: _householdController.mode,
      initialHouseholdMembers: _householdController.copyHouseholdMembers(),
      initialBusinessMembers: _householdController.copyBusinessMembers(),
    );

    if (result == null) {
      return;
    }

    _householdController.applySelection(
      mode: result.mode,
      householdMembers: result.householdMembers,
      businessMembers: result.businessMembers,
    );
  }

  void _handleMemberTap(String personId) {
    final didUpdate = _householdController.toggleVisibleMemberSelection(
      personId,
    );
    if (didUpdate) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr('tns.householdCannotDeselectAll'),
          ),
        ),
      );
  }

  String get _selectionSignature {
    final personIds = _householdController.selectedPersonIds;
    if (personIds.isEmpty) {
      return 'default';
    }
    return personIds.join('|');
  }

  Map<String, ContractsHouseholdMember> get _ownerMembersByPersonId {
    final members = <ContractsHouseholdMember>[
      ..._householdController.householdMembers,
      ..._householdController.businessMembers,
    ];
    final map = <String, ContractsHouseholdMember>{};
    for (final member in members) {
      map[member.personId] = member;
    }
    return map;
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
        profileRepository: widget.profileRepository,
        surveyAddressRepository: widget.surveyAddressRepository,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _householdController,
          builder: (context, _) {
            return Column(
              children: [
                Builder(
                  builder: (innerContext) => FutureBuilder<int>(
                    future: _unreadNotificationsFuture,
                    builder: (context, snapshot) {
                      return AppTopBar(
                        onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                        onNotificationTap: () => _openNotifications(),
                        showBadge: (snapshot.data ?? 0) > 0,
                      );
                    },
                  ),
                ),
                AppPageHeader(title: l10n.tr('tns.myContracts')),
                ContractsHouseholdMemberFilterBar(
                  controller: _householdController,
                  onMemberTap: _handleMemberTap,
                  onArrowTap: _openHouseholdSheet,
                ),
                _ContractTypeTabBar(
                  activeIndex: _activeContractTab,
                  onTabSelected: (i) => setState(() {
                    _activeContractTab = i;
                    // New contract tab starts locked until its next sync notification.
                    _syncUnlockedTabs.clear();
                  }),
                ),
                Expanded(
                  child: _ContractTabContent(
                    activeIndex: _activeContractTab,
                    contractsRepository: widget.contractsRepository,
                    syncNotificationService: widget.syncNotificationService,
                    selectedPersonIds: _householdController.selectedPersonIds,
                    ownerMembersByPersonId: _ownerMembersByPersonId,
                    selectionSignature: _selectionSignature,
                    canAddContracts:
                        _householdController.canOpenAddContractForSelection &&
                        _syncUnlockedTabs.contains(_activeContractTab),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppNavTab.contracts,
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
              ),
            ),
          );
        },
        onContractsTap: () {},
        onRealEstateTap: () => _openPage(const RealEstatePage()),
        onMessagesTap: () => _openPage(const ChatPage()),
      ),
    );
  }
}

class _ContractTypeTabBar extends StatelessWidget {
  const _ContractTypeTabBar({
    required this.activeIndex,
    required this.onTabSelected,
  });

  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  static const _tabs = [
    _TabDef(icon: FilipIcons.investment, labelKey: 'tns.investment'),
    _TabDef(icon: FilipIcons.premium, labelKey: 'tns.nonLifeinsurance'),
    _TabDef(icon: FilipIcons.pension, labelKey: 'tns.retirement'),
    _TabDef(icon: FilipIcons.loan, labelKey: 'tns.loan'),
  ];

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
            final isActive = i == activeIndex;

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

// Ã¢â€â‚¬Ã¢â€â‚¬ Tab content Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _ContractTabContent extends StatelessWidget {
  const _ContractTabContent({
    required this.activeIndex,
    required this.contractsRepository,
    required this.syncNotificationService,
    required this.selectedPersonIds,
    required this.ownerMembersByPersonId,
    required this.selectionSignature,
    required this.canAddContracts,
  });

  final int activeIndex;
  final ContractsRepository contractsRepository;
  final SyncNotificationService syncNotificationService;
  final List<String> selectedPersonIds;
  final Map<String, ContractsHouseholdMember> ownerMembersByPersonId;
  final String selectionSignature;
  final bool canAddContracts;

  @override
  Widget build(BuildContext context) {
    return switch (activeIndex) {
      0 => ContractsInvestmentTab(
        key: ValueKey<String>('investment-$selectionSignature'),
        contractsRepository: contractsRepository,
        syncNotificationService: syncNotificationService,
        personIds: selectedPersonIds,
        ownerMembersByPersonId: ownerMembersByPersonId,
        canAddContracts: canAddContracts,
      ),
      1 => ContractsNonLifeInsuranceTab(
        key: ValueKey<String>('insure-$selectionSignature'),
        contractsRepository: contractsRepository,
        syncNotificationService: syncNotificationService,
        personIds: selectedPersonIds,
        ownerMembersByPersonId: ownerMembersByPersonId,
        canAddContracts: canAddContracts,
      ),
      2 => ContractsRetirementTab(
        key: ValueKey<String>('retirement-$selectionSignature'),
        contractsRepository: contractsRepository,
        personIds: selectedPersonIds,
        ownerMembersByPersonId: ownerMembersByPersonId,
        canAddContracts: canAddContracts,
      ),
      3 => ContractsLoanTab(
        key: ValueKey<String>('loan-$selectionSignature'),
        contractsRepository: contractsRepository,
        personIds: selectedPersonIds,
        ownerMembersByPersonId: ownerMembersByPersonId,
        canAddContracts: canAddContracts,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
