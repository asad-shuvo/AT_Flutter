import 'dart:async';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/chat/presentation/chat_page.dart';
import 'package:filip_at_flutter/features/contracts/application/contracts_household_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contract_detail_page.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_contract_modal.dart';
import 'package:filip_at_flutter/features/contracts/data/insure_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_overview_model.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/presentation/notifications_page.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/real_estate/presentation/real_estate_page.dart';
import 'package:filip_at_flutter/features/explorer/presentation/filip_explorer_page.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/widgets/app_side_drawer.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/widgets/app_bottom_nav.dart';
import 'package:filip_at_flutter/shared/widgets/app_page_header.dart';
import 'package:filip_at_flutter/shared/widgets/app_top_bar.dart';
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
  });

  final ContractsRepository contractsRepository;
  final DashboardRepository dashboardRepository;
  final NotificationsRepository notificationsRepository;
  final AuthSessionController authSessionController;
  final String appVersion;
  final SyncNotificationService syncNotificationService;

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  int _activeContractTab = 0;
  late final Future<UserProfile?> _userProfileFuture;
  late final ContractsHouseholdController _householdController;
  late Future<int> _unreadNotificationsFuture;
  late StreamSubscription<Map<String, dynamic>> _contractSyncSubscription;
  late StreamSubscription<Map<String, dynamic>> _syncCustomerContractSubscription;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = widget.dashboardRepository.fetchUserProfile();
    _householdController = ContractsHouseholdController(
      contractsRepository: widget.contractsRepository,
    )..load();
    _unreadNotificationsFuture = widget.notificationsRepository
        .fetchUnreadCount();

    _contractSyncSubscription = widget.syncNotificationService.contractSyncCompleted.stream.listen((event) {
      if (!mounted) return;
      _householdController.load();
      if (_activeContractTab != 0 && !_shouldSkipContractSyncSnackbar(event)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tr('CONTRACT_SYNC_COMPLETED'))),
        );
      }
    });

    _syncCustomerContractSubscription = widget.syncNotificationService.synccustomercontract.stream.listen((_) {
      if (!mounted) return;
      _householdController.load();
    });
  }

  @override
  void dispose() {
    _householdController.dispose();
    _contractSyncSubscription.cancel();
    _syncCustomerContractSubscription.cancel();
    super.dispose();
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  bool _shouldSkipContractSyncSnackbar(Map<String, dynamic> event) {
    return _readBoolLike(event['SkipContractSync']) ?? false;
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

    final result = await showModalBottomSheet<_ContractsHouseholdSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _ContractsHouseholdSheet(
          initialMode: _householdController.mode,
          initialHouseholdMembers: _householdController.copyHouseholdMembers(),
          initialBusinessMembers: _householdController.copyBusinessMembers(),
        );
      },
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
            context.l10n.tr('contracts.householdCannotDeselectAll'),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      drawer: AppSideDrawer(
        userProfileFuture: _userProfileFuture,
        dashboardRepository: widget.dashboardRepository,
        authSessionController: widget.authSessionController,
        appVersion: widget.appVersion,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _householdController,
          builder: (context, _) {
            return Column(
              children: [
                FutureBuilder<int>(
                  future: _unreadNotificationsFuture,
                  builder: (context, snapshot) {
                    return AppTopBar(
                      onNotificationTap: () => _openNotifications(),
                      showBadge: (snapshot.data ?? 0) > 0,
                    );
                  },
                ),
                AppPageHeader(title: l10n.tr('tns.myContracts')),
                _HouseholdMemberBar(
                  controller: _householdController,
                  onMemberTap: _handleMemberTap,
                  onArrowTap: _openHouseholdSheet,
                ),
                _ContractTypeTabBar(
                  activeIndex: _activeContractTab,
                  onTabSelected: (i) => setState(() => _activeContractTab = i),
                ),
                Expanded(
                  child: _ContractTabContent(
                    activeIndex: _activeContractTab,
                    contractsRepository: widget.contractsRepository,
                    syncNotificationService: widget.syncNotificationService,
                    selectedPersonIds: _householdController.selectedPersonIds,
                    selectionSignature: _selectionSignature,
                    canAddContracts:
                        _householdController.canOpenAddContractForSelection,
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

// â”€â”€ Household member filter bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HouseholdMemberBar extends StatelessWidget {
  const _HouseholdMemberBar({
    required this.controller,
    required this.onMemberTap,
    required this.onArrowTap,
  });

  final ContractsHouseholdController controller;
  final ValueChanged<String> onMemberTap;
  final VoidCallback onArrowTap;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return Container(
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E5E5)),
            bottom: BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ),
        ),
      );
    }

    if (!controller.shouldShowFilter) {
      return const SizedBox.shrink();
    }

    final members = controller.visibleMembers;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
          bottom: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: List.generate(members.length, (i) {
                  final member = members[i];
                  final label = member.isCurrentUser
                      ? context.l10n.tr('tns.me')
                      : member.displayLastName;
                  return GestureDetector(
                    onTap: () => onMemberTap(member.personId),
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.only(left: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: member.isSelected
                            ? const Color(0xFFFFF5F6)
                            : const Color(0xFFF4F4F4),
                        border: Border.all(
                          color: member.isSelected
                              ? AppColors.primaryRed
                              : const Color(0xFFD2D2D2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Row(
                        children: [
                          _MemberAvatar(member: member, size: 37),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 56),
                            child: Text(
                              label.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Calibri',
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Container(
            width: 50,
            height: double.infinity,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: InkWell(
              onTap: onArrowTap,
              child: const Center(
                child: Icon(
                  SelectNetworkIcons.arrowDown,
                  size: 22,
                  color: Color(0xFF808080),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.size});

  final ContractsHouseholdMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (member.hasRenderableProfileImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          member.profileImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _MemberAvatarFallback(member: member, size: size);
          },
        ),
      );
    }

    return _MemberAvatarFallback(member: member, size: size);
  }
}

class _MemberAvatarFallback extends StatelessWidget {
  const _MemberAvatarFallback({required this.member, required this.size});

  final ContractsHouseholdMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: member.avatarColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          member.fallbackInitial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontFamily: 'Calibri',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Contract type tab bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ContractsHouseholdSheetResult {
  const _ContractsHouseholdSheetResult({
    required this.mode,
    required this.householdMembers,
    required this.businessMembers,
  });

  final ContractsHouseholdMode mode;
  final List<ContractsHouseholdMember> householdMembers;
  final List<ContractsHouseholdMember> businessMembers;
}

class _ContractsHouseholdSheet extends StatefulWidget {
  const _ContractsHouseholdSheet({
    required this.initialMode,
    required this.initialHouseholdMembers,
    required this.initialBusinessMembers,
  });

  final ContractsHouseholdMode initialMode;
  final List<ContractsHouseholdMember> initialHouseholdMembers;
  final List<ContractsHouseholdMember> initialBusinessMembers;

  @override
  State<_ContractsHouseholdSheet> createState() =>
      _ContractsHouseholdSheetState();
}

class _ContractsHouseholdSheetState extends State<_ContractsHouseholdSheet> {
  late ContractsHouseholdMode _mode;
  late List<ContractsHouseholdMember> _householdMembers;
  late List<ContractsHouseholdMember> _businessMembers;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialBusinessMembers.isEmpty
        ? ContractsHouseholdMode.household
        : widget.initialMode;
    _householdMembers = widget.initialHouseholdMembers;
    _businessMembers = widget.initialBusinessMembers;
  }

  bool get _isHouseholdMode => _mode == ContractsHouseholdMode.household;

  List<ContractsHouseholdMember> get _visibleMembers {
    return _isHouseholdMode ? _householdMembers : _businessMembers;
  }

  bool get _isAllSelected =>
      ContractsHouseholdController.areAllSelected(_householdMembers);

  bool get _canApply =>
      ContractsHouseholdController.hasAtLeastOneSelected(_visibleMembers);

  void _switchMode(ContractsHouseholdMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
      if (_isHouseholdMode) {
        _businessMembers = ContractsHouseholdController.setSelectionForAll(
          _businessMembers,
          false,
        );
        _householdMembers = ContractsHouseholdController.ensureFirstSelected(
          _householdMembers,
        );
      } else {
        _householdMembers = ContractsHouseholdController.setSelectionForAll(
          _householdMembers,
          false,
        );
        _businessMembers = ContractsHouseholdController.ensureFirstSelected(
          _businessMembers,
        );
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _householdMembers = ContractsHouseholdController.setSelectionForAll(
        _householdMembers,
        !_isAllSelected,
      );
      _businessMembers = ContractsHouseholdController.setSelectionForAll(
        _businessMembers,
        false,
      );
    });
  }

  void _toggleMember(String personId) {
    setState(() {
      if (_isHouseholdMode) {
        _businessMembers = ContractsHouseholdController.setSelectionForAll(
          _businessMembers,
          false,
        );
        _householdMembers = _householdMembers
            .map(
              (member) => member.personId == personId
                  ? member.copyWith(isSelected: !member.isSelected)
                  : member,
            )
            .toList(growable: false);
      } else {
        _householdMembers = ContractsHouseholdController.setSelectionForAll(
          _householdMembers,
          false,
        );
        _businessMembers = _businessMembers
            .map(
              (member) => member.personId == personId
                  ? member.copyWith(isSelected: !member.isSelected)
                  : member,
            )
            .toList(growable: false);
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _ContractsHouseholdSheetResult(
        mode: _mode,
        householdMembers: _householdMembers,
        businessMembers: _businessMembers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 540,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0B8C0),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SheetModeTab(
                          label:
                              '${l10n.tr('tns.household')} (${_householdMembers.length})',
                          isActive: _isHouseholdMode,
                          onTap: () =>
                              _switchMode(ContractsHouseholdMode.household),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: widget.initialBusinessMembers.isNotEmpty
                            ? _SheetModeTab(
                                label:
                                    '${l10n.tr('tns.business')} (${_businessMembers.length})',
                                isActive: !_isHouseholdMode,
                                onTap: () => _switchMode(
                                  ContractsHouseholdMode.business,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isHouseholdMode) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        l10n.tr('tns.multipleSelection'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Calibri',
                          color: Color(0xFF666666),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleSelectAll,
                        child: Row(
                          children: [
                            Text(
                              l10n.tr('tns.selectAll'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Calibri',
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isAllSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 22,
                              color: AppColors.primaryRed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  itemCount: _visibleMembers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFEAEAEA)),
                  itemBuilder: (context, index) {
                    final member = _visibleMembers[index];
                    return InkWell(
                      onTap: () => _toggleMember(member.personId),
                      child: SizedBox(
                        height: 70,
                        child: Row(
                          children: [
                            _MemberAvatar(member: member, size: 42),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.isCurrentUser && _isHouseholdMode
                                    ? '${member.displayName} (${l10n.tr('tns.me')})'
                                    : member.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Calibri',
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            if (member.isSelected)
                              const Icon(
                                Icons.done,
                                size: 22,
                                color: AppColors.primaryRed,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canApply ? _apply : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD8D8D8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.tr('tns.showContracts'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Calibri',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetModeTab extends StatelessWidget {
  const _SheetModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
          ),
          boxShadow: isActive
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Calibri',
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xFF333333),
            ),
          ),
        ),
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

// â”€â”€ Tab content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ContractTabContent extends StatelessWidget {
  const _ContractTabContent({
    required this.activeIndex,
    required this.contractsRepository,
    required this.syncNotificationService,
    required this.selectedPersonIds,
    required this.selectionSignature,
    required this.canAddContracts,
  });

  final int activeIndex;
  final ContractsRepository contractsRepository;
  final SyncNotificationService syncNotificationService;
  final List<String> selectedPersonIds;
  final String selectionSignature;
  final bool canAddContracts;

  @override
  Widget build(BuildContext context) {
    return switch (activeIndex) {
      0 => _InvestmentTab(
        key: ValueKey<String>('investment-$selectionSignature'),
        contractsRepository: contractsRepository,
        syncNotificationService: syncNotificationService,
        personIds: selectedPersonIds,
        canAddContracts: canAddContracts,
      ),
      1 => _NonLifeInsuranceTab(
        key: ValueKey<String>('insure-$selectionSignature'),
        contractsRepository: contractsRepository,
        personIds: selectedPersonIds,
        canAddContracts: canAddContracts,
      ),
      2 => _RetirementTab(
        key: ValueKey<String>('retirement-$selectionSignature'),
        contractsRepository: contractsRepository,
        personIds: selectedPersonIds,
        canAddContracts: canAddContracts,
      ),
      3 => _LoanTab(
        key: ValueKey<String>('loan-$selectionSignature'),
        contractsRepository: contractsRepository,
        personIds: selectedPersonIds,
        canAddContracts: canAddContracts,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

// â”€â”€ Investment tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

void _showContractsSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

enum _ContractDeleteSheetResult { cancelled, deleted, failed }

Future<_ContractDeleteSheetResult> _showContractDeleteBottomSheet(
  BuildContext context, {
  required Future<void> Function() onConfirmDelete,
}) async {
  final l10n = context.l10n;
  final result = await showModalBottomSheet<_ContractDeleteSheetResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) {
      var isDeleting = false;

      Future<void> confirmDelete(StateSetter setModalState) async {
        if (isDeleting) return;
        setModalState(() => isDeleting = true);
        try {
          await onConfirmDelete();
          if (!context.mounted) return;
          Navigator.of(context).pop(_ContractDeleteSheetResult.deleted);
        } catch (_) {
          if (!context.mounted) return;
          Navigator.of(context).pop(_ContractDeleteSheetResult.failed);
        }
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDeleting)
                      const LinearProgressIndicator(
                        minHeight: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryRed,
                        ),
                      ),
                    const SizedBox(height: 34),
                    const Icon(
                      IconData(
                        0xE9F9,
                        fontFamily: 'filip_at_iconpack_29022024',
                      ),
                      size: 72,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        l10n.tr('tns.deleteContractConfirmPrompt'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 22,
                          color: Color(0xFF333333),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pop(_ContractDeleteSheetResult.cancelled),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFD0D0D0),
                                ),
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                l10n.tr('tns.cancel').toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 18,
                                  fontFamily: 'Calibri',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => confirmDelete(setModalState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                disabledBackgroundColor: AppColors.primaryRed,
                                minimumSize: const Size.fromHeight(58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isDeleting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.tr('tns.deleting').toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'Calibri',
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      l10n.tr('tns.confirm').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontFamily: 'Calibri',
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.6,
                                      ),
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
        },
      );
    },
  );
  return result ?? _ContractDeleteSheetResult.cancelled;
}

class _NonLifeInsuranceTab extends StatefulWidget {
  const _NonLifeInsuranceTab({
    super.key,
    required this.contractsRepository,
    required this.personIds,
    required this.canAddContracts,
  });

  final ContractsRepository contractsRepository;
  final List<String> personIds;
  final bool canAddContracts;

  @override
  State<_NonLifeInsuranceTab> createState() => _NonLifeInsuranceTabState();
}

class _NonLifeInsuranceTabState extends State<_NonLifeInsuranceTab> {
  late Future<void> _syncFuture;
  late Future<InsureOverview?> _overviewFuture;
  late Future<InsureContractsData?> _contractsFuture;
  bool _isReloadingContracts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _syncFuture = _runSync();
    _overviewFuture = _syncFuture.then((_) {
      return widget.contractsRepository.fetchNonLifeInsureOverview(
        personIds: widget.personIds,
      );
    });
    _contractsFuture = _syncFuture.then((_) {
      return widget.contractsRepository.fetchNonLifeInsureContracts(
        personIds: widget.personIds,
      );
    });
  }

  Future<void> _runSync() async {
    try {
      await widget.contractsRepository.syncContractsData(
        personIds: widget.personIds,
      );
    } catch (_) {
      // Keep rendering last-known server data even if sync is unavailable.
    }
  }

  Future<void> _reloadContractsAfterDelete() async {
    setState(() {
      _isReloadingContracts = true;
      _loadData();
    });
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        _overviewFuture,
        _contractsFuture,
      ]);
    } catch (_) {
      // Keep existing data if refresh fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _isReloadingContracts = false;
      });
    }
  }

  Future<void> _handleEditAction(InsureContract contract) async {
    final updated = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.insurance,
      repository: widget.contractsRepository,
      initialData: ContractsAddInitialData(
        isEdit: true,
        contractId: contract.itemId,
        title: contract.title,
        typeValueOrLabel: contract.type,
        partnerName: contract.partnerName,
        grossPremium: contract.grossPremium?.toString(),
        endDate: contract.endDate,
        contractNumber: contract.contractNumber,
        startDate: contract.startDate,
        premiumFrequencyValueOrLabel: contract.premiumFrequency,
        insuranceAmount: contract.maturityBenefits?.toString(),
        notes: contract.notes,
        status: contract.status,
        isLifeTime: contract.isLifeTime,
        syncDisabledProperties: contract.syncDisabledProperties,
      ),
    );
    if (!mounted || updated != true) return;
    await _reloadContractsAfterDelete();
  }

  Future<void> _handleDeleteAction(InsureContract contract) async {
    final result = await _showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Insure',
        contractItemId: contract.itemId,
      ),
    );
    if (!mounted || result == _ContractDeleteSheetResult.cancelled) return;
    if (result == _ContractDeleteSheetResult.failed) {
      _showContractsSnackBar(
        context,
        context.l10n.tr('tns.contractDeleteFailed'),
      );
      return;
    }

    await _reloadContractsAfterDelete();
    if (!mounted) return;
    _showContractsSnackBar(context, context.l10n.tr('tns.contractDeleted'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<InsureOverview?>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _OverviewLoadingState(
                    message: l10n.tr('common.loading'),
                  );
                }

                final data = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            SelectNetworkIcons.premium,
                            size: 26,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OverviewRow(
                              label: l10n.tr('dashboard.monthlyPremium'),
                              value: data == null
                                  ? '...'
                                  : _formatCurrency(data.monthlyPremium),
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('tns.annualPremium'),
                              value: data == null
                                  ? '...'
                                  : _formatCurrency(data.annualPremium),
                              valueBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<InsureContractsData?>(
            future: _contractsFuture,
            builder: (context, snapshot) {
              final contractsData = _isReloadingContracts
                  ? null
                  : snapshot.data;
              final isLoadingContracts =
                  _isReloadingContracts ||
                  (snapshot.connectionState == ConnectionState.waiting &&
                      contractsData == null);
              final countLabel = contractsData != null
                  ? contractsData.totalCount.toString()
                  : isLoadingContracts
                  ? '...'
                  : '0';

              return Column(
                children: [
                  _ContractsSectionHeader(
                    label: l10n.tr('tns.insuranceContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: widget.canAddContracts
                        ? _showAddInsuranceForm
                        : null,
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingContracts)
                    _ContractsListLoadingState(
                      message: l10n.tr('common.loading'),
                    )
                  else if (contractsData == null ||
                      contractsData.contracts.isEmpty)
                    _EmptyState(message: l10n.tr('tns.noDataAddedYet'))
                  else
                    Column(
                      children: List<Widget>.generate(
                        contractsData.contracts.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == contractsData.contracts.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _InsureContractCard(
                            contract: contractsData.contracts[index],
                            currentPersonId: contractsData.currentPersonId,
                            formatCurrency: _formatCurrency,
                            formatDate: _formatDate,
                            formatType: _formatType,
                            onEditTap: () =>
                                _handleEditAction(contractsData.contracts[index]),
                            onDeleteTap: () => _handleDeleteAction(
                              contractsData.contracts[index],
                            ),
                            onTap: () async {
                              final edited = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ContractDetailPage.fromInsure(contract: contractsData.contracts[index], entityName: 'Insure', contractsRepository: widget.contractsRepository, currentPersonId: contractsData.currentPersonId,),),);
                              if (edited == true && mounted) await _reloadContractsAfterDelete();
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoSheet() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FilipIcons.about,
                        size: 20,
                        color: Color(0xFFB7B7B7),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.tr('tns.importantNotice'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Calibri',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Text(
                    l10n.tr('tns.insureinfotext'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Calibri',
                      color: Color(0xFF555555),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddInsuranceForm() async {
    final created = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.insurance,
      repository: widget.contractsRepository,
    );
    if (!mounted || created != true) return;
    await _reloadContractsAfterDelete();
  }

  String _formatCurrency(double value) {
    final absValue = value.abs();
    final parts = absValue.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    final result = '$intPart,${parts[1]}';
    return '\u20AC ${value < 0 ? '-' : ''}$result';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }

  String _formatType(String? value) {
    if (value == null || value.isEmpty) return '-';
    return context.l10n.trBestEffort(value);
  }
}

class _RetirementTab extends StatefulWidget {
  const _RetirementTab({
    super.key,
    required this.contractsRepository,
    required this.personIds,
    required this.canAddContracts,
  });

  final ContractsRepository contractsRepository;
  final List<String> personIds;
  final bool canAddContracts;

  @override
  State<_RetirementTab> createState() => _RetirementTabState();
}

class _RetirementTabState extends State<_RetirementTab> {
  late Future<void> _syncFuture;
  late Future<InsureOverview?> _overviewFuture;
  late Future<InsureContractsData?> _contractsFuture;
  bool _isReloadingContracts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _syncFuture = _runSync();
    _overviewFuture = _syncFuture.then((_) {
      return widget.contractsRepository.fetchRetirementOverview(
        personIds: widget.personIds,
      );
    });
    _contractsFuture = _syncFuture.then((_) {
      return widget.contractsRepository.fetchRetirementContracts(
        personIds: widget.personIds,
      );
    });
  }

  Future<void> _runSync() async {
    try {
      await widget.contractsRepository.syncContractsData(
        personIds: widget.personIds,
      );
    } catch (_) {
      // Keep rendering last-known server data even if sync is unavailable.
    }
  }

  Future<void> _reloadContractsAfterDelete() async {
    setState(() {
      _isReloadingContracts = true;
      _loadData();
    });
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        _overviewFuture,
        _contractsFuture,
      ]);
    } catch (_) {
      // Keep existing data if refresh fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _isReloadingContracts = false;
      });
    }
  }

  Future<void> _handleEditAction(InsureContract contract) async {
    final updated = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.retirement,
      repository: widget.contractsRepository,
      initialData: ContractsAddInitialData(
        isEdit: true,
        contractId: contract.itemId,
        title: contract.title,
        typeValueOrLabel: contract.type,
        partnerName: contract.partnerName,
        grossPremium: contract.grossPremium?.toString(),
        endDate: contract.endDate,
        contractNumber: contract.contractNumber,
        startDate: contract.startDate,
        premiumFrequencyValueOrLabel: contract.premiumFrequency,
        insuranceAmount: contract.maturityBenefits?.toString(),
        notes: contract.notes,
        status: contract.status,
        dueDate: contract.dueDate,
        syncDisabledProperties: contract.syncDisabledProperties,
      ),
    );
    if (!mounted || updated != true) return;
    await _reloadContractsAfterDelete();
  }

  Future<void> _handleDeleteAction(InsureContract contract) async {
    final result = await _showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Insure',
        contractItemId: contract.itemId,
      ),
    );
    if (!mounted || result == _ContractDeleteSheetResult.cancelled) return;
    if (result == _ContractDeleteSheetResult.failed) {
      _showContractsSnackBar(
        context,
        context.l10n.tr('tns.contractDeleteFailed'),
      );
      return;
    }

    await _reloadContractsAfterDelete();
    if (!mounted) return;
    _showContractsSnackBar(context, context.l10n.tr('tns.contractDeleted'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<InsureOverview?>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _OverviewLoadingState(
                    message: l10n.tr('common.loading'),
                  );
                }

                final data = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            SelectNetworkIcons.premium,
                            size: 26,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OverviewRow(
                              label: l10n.tr('dashboard.monthlyPayment'),
                              value: data == null
                                  ? '...'
                                  : _formatCurrency(data.monthlyPremium),
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('dashboard.yearlyPayment'),
                              value: data == null
                                  ? '...'
                                  : _formatCurrency(data.annualPremium),
                              valueBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _ContractsPromoCard(
            title: l10n.tr('tns.realEstateOverview'),
            subtitle: l10n.tr('tns.realEstateOverviewBody'),
            icon: FilipIcons.loan,
          ),
          const SizedBox(height: 12),
          FutureBuilder<InsureContractsData?>(
            future: _contractsFuture,
            builder: (context, snapshot) {
              final contractsData = _isReloadingContracts
                  ? null
                  : snapshot.data;
              final isLoadingContracts =
                  _isReloadingContracts ||
                  (snapshot.connectionState == ConnectionState.waiting &&
                      contractsData == null);
              final countLabel = contractsData != null
                  ? contractsData.totalCount.toString()
                  : isLoadingContracts
                  ? '...'
                  : '0';

              return Column(
                children: [
                  _ContractsSectionHeader(
                    label: l10n.tr('tns.retirementContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: widget.canAddContracts
                        ? _showAddRetirementForm
                        : null,
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingContracts)
                    _ContractsListLoadingState(
                      message: l10n.tr('common.loading'),
                    )
                  else if (contractsData == null ||
                      contractsData.contracts.isEmpty)
                    _EmptyState(message: l10n.tr('tns.noDataAddedYet'))
                  else
                    Column(
                      children: List<Widget>.generate(
                        contractsData.contracts.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == contractsData.contracts.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _InsureContractCard(
                            contract: contractsData.contracts[index],
                            currentPersonId: contractsData.currentPersonId,
                            formatCurrency: _formatCurrency,
                            formatDate: _formatDate,
                            formatType: _formatType,
                            endDatePrefix: l10n.tr('tns.endDate'),
                            onEditTap: () =>
                                _handleEditAction(contractsData.contracts[index]),
                            onDeleteTap: () => _handleDeleteAction(
                              contractsData.contracts[index],
                            ),
                            onTap: () async {
                              final edited = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ContractDetailPage.fromInsure(contract: contractsData.contracts[index], entityName: 'Retirement', contractsRepository: widget.contractsRepository, currentPersonId: contractsData.currentPersonId,),),);
                              if (edited == true && mounted) await _reloadContractsAfterDelete();
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoSheet() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FilipIcons.about,
                        size: 20,
                        color: Color(0xFFB7B7B7),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.tr('tns.importantNotice'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Calibri',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Text(
                    l10n.tr('tns.retirementInfoText'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Calibri',
                      color: Color(0xFF555555),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddRetirementForm() async {
    final created = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.retirement,
      repository: widget.contractsRepository,
    );
    if (!mounted || created != true) return;
    await _reloadContractsAfterDelete();
  }

  String _formatCurrency(double value) {
    final absValue = value.abs();
    final parts = absValue.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    final result = '$intPart,${parts[1]}';
    return '\u20AC ${value < 0 ? '-' : ''}$result';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }

  String _formatType(String? value) {
    if (value == null || value.isEmpty) return '-';
    return context.l10n.trBestEffort(value);
  }
}

class _InvestmentTab extends StatefulWidget {
  const _InvestmentTab({
    super.key,
    required this.contractsRepository,
    required this.syncNotificationService,
    required this.personIds,
    required this.canAddContracts,
  });

  final ContractsRepository contractsRepository;
  final SyncNotificationService syncNotificationService;
  final List<String> personIds;
  final bool canAddContracts;

  @override
  State<_InvestmentTab> createState() => _InvestmentTabState();
}

class _LoanTab extends StatefulWidget {
  const _LoanTab({
    super.key,
    required this.contractsRepository,
    required this.personIds,
    required this.canAddContracts,
  });

  final ContractsRepository contractsRepository;
  final List<String> personIds;
  final bool canAddContracts;

  @override
  State<_LoanTab> createState() => _LoanTabState();
}

class _LoanTabState extends State<_LoanTab> {
  late Future<void> _syncFuture;
  late Future<InsureOverview?> _overviewFuture;
  late Future<InsureContractsData?> _contractsFuture;
  bool _isReloadingContracts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _syncFuture = _runSync();
    _overviewFuture = _syncFuture.then((_) {
      return widget.contractsRepository.fetchLoanOverview(
        personIds: widget.personIds,
      );
    });
    _contractsFuture = _syncFuture.then((_) {
      return widget.contractsRepository.fetchLoanContracts(
        personIds: widget.personIds,
      );
    });
  }

  Future<void> _runSync() async {
    try {
      await widget.contractsRepository.syncContractsData(
        personIds: widget.personIds,
      );
    } catch (_) {
      // Keep rendering last-known server data even if sync is unavailable.
    }
  }

  Future<void> _reloadContractsAfterDelete() async {
    setState(() {
      _isReloadingContracts = true;
      _loadData();
    });
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        _overviewFuture,
        _contractsFuture,
      ]);
    } catch (_) {
      // Keep existing data if refresh fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _isReloadingContracts = false;
      });
    }
  }

  Future<void> _handleEditAction(InsureContract contract) async {
    final updated = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.loan,
      repository: widget.contractsRepository,
      initialData: ContractsAddInitialData(
        isEdit: true,
        contractId: contract.itemId,
        title: contract.title,
        typeValueOrLabel: contract.type,
        partnerName: contract.partnerName,
        contractNumber: contract.contractNumber,
        loanAmount: contract.grossPremium?.toString(),
        tradeInValue: contract.maturityBenefits?.toString(),
        startDate: contract.startDate,
        endDate: contract.endDate,
        startOfRepayment: null,
        remainingDebtDate: contract.dueDate,
        remainingAmount: null,
        notes: contract.notes,
        status: contract.status,
        syncDisabledProperties: contract.syncDisabledProperties,
      ),
    );
    if (!mounted || updated != true) return;
    await _reloadContractsAfterDelete();
  }

  Future<void> _handleDeleteAction(InsureContract contract) async {
    final result = await _showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Loan',
        contractItemId: contract.itemId,
      ),
    );
    if (!mounted || result == _ContractDeleteSheetResult.cancelled) return;
    if (result == _ContractDeleteSheetResult.failed) {
      _showContractsSnackBar(
        context,
        context.l10n.tr('tns.contractDeleteFailed'),
      );
      return;
    }

    await _reloadContractsAfterDelete();
    if (!mounted) return;
    _showContractsSnackBar(context, context.l10n.tr('tns.contractDeleted'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<InsureOverview?>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _OverviewLoadingState(
                    message: l10n.tr('common.loading'),
                  );
                }

                final data = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            SelectNetworkIcons.premium,
                            size: 26,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OverviewRow(
                              label: l10n.tr('dashboard.monthlyPayment'),
                              value: data == null
                                  ? '...'
                                  : _formatCurrency(data.monthlyPremium),
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('dashboard.yearlyPayment'),
                              value: data == null
                                  ? '...'
                                  : _formatCurrency(data.annualPremium),
                              valueBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _ContractsPromoCard(
            title: l10n.tr('tns.realEstateOverview'),
            subtitle: l10n.tr('tns.realEstateOverviewBody'),
            icon: FilipIcons.loan,
          ),
          const SizedBox(height: 12),
          FutureBuilder<InsureContractsData?>(
            future: _contractsFuture,
            builder: (context, snapshot) {
              final contractsData = _isReloadingContracts
                  ? null
                  : snapshot.data;
              final isLoadingContracts =
                  _isReloadingContracts ||
                  (snapshot.connectionState == ConnectionState.waiting &&
                      contractsData == null);
              final countLabel = contractsData != null
                  ? contractsData.totalCount.toString()
                  : isLoadingContracts
                  ? '...'
                  : '0';

              return Column(
                children: [
                  _ContractsSectionHeader(
                    label: l10n.tr('tns.loanContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: widget.canAddContracts ? _showAddLoanForm : null,
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingContracts)
                    _ContractsListLoadingState(
                      message: l10n.tr('common.loading'),
                    )
                  else if (contractsData == null ||
                      contractsData.contracts.isEmpty)
                    _EmptyState(message: l10n.tr('tns.noDataAddedYet'))
                  else
                    Column(
                      children: List<Widget>.generate(
                        contractsData.contracts.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == contractsData.contracts.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _InsureContractCard(
                            contract: contractsData.contracts[index],
                            currentPersonId: contractsData.currentPersonId,
                            formatCurrency: _formatCurrency,
                            formatDate: _formatDate,
                            formatType: _formatType,
                            onEditTap: () =>
                                _handleEditAction(contractsData.contracts[index]),
                            onDeleteTap: () => _handleDeleteAction(
                              contractsData.contracts[index],
                            ),
                            onTap: () async {
                              final edited = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ContractDetailPage.fromInsure(contract: contractsData.contracts[index], entityName: 'Loan', contractsRepository: widget.contractsRepository, currentPersonId: contractsData.currentPersonId,),),);
                              if (edited == true && mounted) await _reloadContractsAfterDelete();
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoSheet() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FilipIcons.about,
                        size: 20,
                        color: Color(0xFFB7B7B7),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.tr('tns.importantNotice'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Calibri',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Text(
                    l10n.tr('tns.insureinfotext'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Calibri',
                      color: Color(0xFF555555),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddLoanForm() async {
    final created = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.loan,
      repository: widget.contractsRepository,
    );
    if (!mounted || created != true) return;
    await _reloadContractsAfterDelete();
  }

  String _formatCurrency(double value) {
    final absValue = value.abs();
    final parts = absValue.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    final result = '$intPart,${parts[1]}';
    return '\u20AC ${value < 0 ? '-' : ''}$result';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }

  String _formatType(String? value) {
    if (value == null || value.isEmpty) return '-';
    return context.l10n.trBestEffort(value);
  }
}

class _InvestmentTabState extends State<_InvestmentTab> {
  late Future<void> _syncFuture;
  late Future<InvestmentOverview?> _overviewFuture;
  late Future<InvestmentContractsData?> _contractsFuture;
  late final StreamSubscription<Map<String, dynamic>> _investmentContractSyncSubscription;
  late final StreamSubscription<Map<String, dynamic>> _contractSyncSubscription;
  bool _expanded = false;
  bool _isReloadingContracts = false;
  bool _isRefreshingFromSyncNotification = false;
  bool _isAdditiveSyncComplete = false;
  bool _isKvvSyncComplete = false;
  bool _skipSnackbar = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _investmentContractSyncSubscription = widget
        .syncNotificationService
        .investmentContractSyncCompleted
        .stream
        .listen(_handleInvestmentContractSyncCompleted);
    _contractSyncSubscription = widget
        .syncNotificationService
        .contractSyncCompleted
        .stream
        .listen(_handleContractSyncCompleted);
  }

  @override
  void dispose() {
    _investmentContractSyncSubscription.cancel();
    _contractSyncSubscription.cancel();
    super.dispose();
  }

  void _loadData({bool triggerSync = true}) {
    final loadGate = triggerSync ? _runSync() : Future<void>.value();
    _syncFuture = loadGate;
    _overviewFuture = loadGate.then((_) {
      return widget.contractsRepository.fetchInvestmentOverview(
        personIds: widget.personIds,
      );
    });
    _contractsFuture = loadGate.then((_) {
      return widget.contractsRepository.fetchInvestmentContracts(
        personIds: widget.personIds,
      );
    });
  }

  Future<void> _runSync() async {
    try {
      await widget.contractsRepository.syncInvestmentContracts(
        personIds: widget.personIds,
      );
    } catch (_) {
      // Keep rendering last-known server data even if sync is unavailable.
    }
  }

  Future<void> _reloadContractsAfterDelete() async {
    setState(() {
      _isReloadingContracts = true;
      _loadData();
    });
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        _overviewFuture,
        _contractsFuture,
      ]);
    } catch (_) {
      // Keep existing data if refresh fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _isReloadingContracts = false;
      });
    }
  }

  void _handleInvestmentContractSyncCompleted(Map<String, dynamic> event) {
    final skipSnackbar = _readBoolLike(event['SkipContractSync']);
    if (skipSnackbar != null) {
      _skipSnackbar = skipSnackbar;
    }
    _isAdditiveSyncComplete = true;
    _handleSyncCycleCompleted();
  }

  void _handleContractSyncCompleted(Map<String, dynamic> _) {
    _isKvvSyncComplete = true;
    _handleSyncCycleCompleted();
  }

  void _handleSyncCycleCompleted() {
    if (!mounted ||
        widget.personIds.isEmpty ||
        !_isKvvSyncComplete ||
        !_isAdditiveSyncComplete ||
        _isRefreshingFromSyncNotification) {
      return;
    }

    _refreshDataAfterSyncNotification();
  }

  Future<void> _refreshDataAfterSyncNotification() async {
    setState(() {
      _isRefreshingFromSyncNotification = true;
      _loadData(triggerSync: false);
    });

    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        _overviewFuture,
        _contractsFuture,
      ]);
    } catch (_) {
      // Preserve the previous render if the post-sync refresh fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefreshingFromSyncNotification = false;
      });
    }

    if (!mounted) return;
    if (!_skipSnackbar) {
      _showContractsSnackBar(
        context,
        context.l10n.tr('CONTRACT_SYNC_COMPLETED'),
      );
    }
    _isAdditiveSyncComplete = false;
    _isKvvSyncComplete = false;
  }

  Future<void> _handleEditAction(InvestmentContract contract) async {
    final updated = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.investment,
      repository: widget.contractsRepository,
      initialData: ContractsAddInitialData(
        isEdit: true,
        contractId: contract.itemId,
        title: contract.title,
        typeValueOrLabel: contract.investmentType,
        partnerName: contract.partnerName,
        contractNumber: contract.contractNumber,
        accountNumber: contract.accountNumber,
        bookValue: contract.investmentBookValue?.toString(),
        currentValue: contract.investmentCurrentValue?.toString(),
        lumpSumInvestment: contract.lumpSumInvestment?.toString(),
        notes: contract.notes,
        startDate: contract.investmentStartDate,
        endDate: contract.investmentEndDate,
        bookValueDate: contract.bookValueDate,
        currentValueDate: contract.currentValueDate,
        bondPriceDate: contract.bondPriceDate,
        isin: contract.isin,
        risk: contract.risk?.toString(),
        numberOfShares: contract.numberOfShares?.toString(),
        currentShareValue: contract.currentShareValue?.toString(),
        interestRate: contract.interestRate?.toString(),
        couponRate: contract.couponRate?.toString(),
        couponTypeValueOrLabel: contract.couponType,
        couponPeriodValueOrLabel: null,
        currencyValueOrLabel: contract.currency,
        issuer: contract.issuer,
        bondPrice: contract.bondPrice?.toString(),
        iban: contract.iban,
        bic: contract.bic,
        paymentFrequencyValueOrLabel: contract.paymentFrequency,
        isTargetSumSavingsPlan: contract.isTargetSumSavingsPlan,
        isPremiumBenefit: contract.isPremiumBenefit,
      ),
    );
    if (!mounted || updated != true) return;
    await _reloadContractsAfterDelete();
  }

  Future<void> _handleDeleteAction(InvestmentContract contract) async {
    final result = await _showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Investment',
        contractItemId: contract.itemId,
      ),
    );
    if (!mounted || result == _ContractDeleteSheetResult.cancelled) return;
    if (result == _ContractDeleteSheetResult.failed) {
      _showContractsSnackBar(
        context,
        context.l10n.tr('tns.contractDeleteFailed'),
      );
      return;
    }

    await _reloadContractsAfterDelete();
    if (!mounted) return;
    _showContractsSnackBar(context, context.l10n.tr('tns.contractDeleted'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          // Personal Performance card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<InvestmentOverview?>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _OverviewLoadingState(
                    message: l10n.tr('common.loading'),
                  );
                }

                final data = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEEEEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                SelectNetworkIcons.premium,
                                size: 26,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _OverviewRow(
                                  label: l10n.tr('tns.personalPerformance'),
                                  value: data == null
                                      ? '...'
                                      : data.personalPerformance != null
                                      ? '${data.personalPerformance!.toStringAsFixed(2).replaceAll('.', ',')}%'
                                      : 'N/A',
                                ),
                                const SizedBox(height: 4),
                                _OverviewRow(
                                  label: l10n.tr('tns.totalInvestment'),
                                  value: data == null
                                      ? '...'
                                      : data.totalInvestment != null
                                      ? _formatCurrency(data.totalInvestment!)
                                      : 'N/A',
                                  valueBold: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_expanded && data != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(74, 4, 14, 0),
                        child: Column(
                          children: [
                            _OverviewRow(
                              label: l10n.tr('tns.investmentRisk'),
                              value: data.investmentRisk ?? '-',
                              valueColor: const Color(0xFF3BAF8E),
                              valueBold: true,
                              dot: true,
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('tns.investorProfile'),
                              value: data.investorProfile ?? '-',
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('tns.moneyMarketAccount'),
                              value: data.moneyMarketAccount != null
                                  ? _formatCurrency(data.moneyMarketAccount!)
                                  : '-',
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('tns.clearingAccount'),
                              value: data.clearingAccount != null
                                  ? _formatCurrency(data.clearingAccount!)
                                  : '-',
                            ),
                            const SizedBox(height: 4),
                            _OverviewRow(
                              label: l10n.tr('tns.fixedDepositAccounts'),
                              value: data.fixedDepositAccounts != null
                                  ? _formatCurrency(data.fixedDepositAccounts!)
                                  : '-',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFD0D0D0)),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.fromHeight(36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _expanded
                                  ? l10n.tr('tns.seeLess')
                                  : l10n.tr('tns.seeMore'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: const Color(0xFF555555),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          _ContractsPromoCard(
            title: l10n.tr('tns.investmentDetails'),
            subtitle: l10n.tr('tns.investmentDetailsSubtitle'),
            icon: SelectNetworkIcons.linkConnect,
          ),

          const SizedBox(height: 12),

          FutureBuilder<InvestmentContractsData?>(
            future: _contractsFuture,
            builder: (context, snapshot) {
              final contractsData = _isReloadingContracts
                  ? null
                  : snapshot.data;
              final isLoadingContracts =
                  _isReloadingContracts ||
                  (snapshot.connectionState == ConnectionState.waiting &&
                      contractsData == null);
              final countLabel = contractsData != null
                  ? contractsData.totalCount.toString()
                  : isLoadingContracts
                  ? '...'
                  : '0';

              return Column(
                children: [
                  _ContractsSectionHeader(
                    label: l10n.tr('tns.investmentContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: widget.canAddContracts
                        ? _showAddInvestmentForm
                        : null,
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingContracts)
                    _ContractsListLoadingState(
                      message: l10n.tr('common.loading'),
                    )
                  else if (contractsData == null ||
                      contractsData.contracts.isEmpty)
                    _EmptyState(message: context.l10n.tr('tns.noDataAddedYet'))
                  else
                    Column(
                      children: List<Widget>.generate(
                        contractsData.contracts.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == contractsData.contracts.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _InvestmentContractCard(
                            contract: contractsData.contracts[index],
                            currentPersonId: contractsData.currentPersonId,
                            formatCurrency: _formatCurrency,
                            formatDate: _formatDate,
                            formatInvestmentType: _formatInvestmentType,
                            onEditTap: () =>
                                _handleEditAction(contractsData.contracts[index]),
                            onDeleteTap: () => _handleDeleteAction(
                              contractsData.contracts[index],
                            ),
                            onTap: () async {
                              final edited = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ContractDetailPage.fromInvestment(contract: contractsData.contracts[index], contractsRepository: widget.contractsRepository, currentPersonId: contractsData.currentPersonId,),),);
                              if (edited == true && mounted) await _reloadContractsAfterDelete();
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final absValue = value.abs();
    final parts = absValue.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    final result = '$intPart,${parts[1]}';
    return '\u20AC ${value < 0 ? '-' : ''}$result';
  }

  Future<void> _showInfoSheet() async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FilipIcons.about,
                        size: 20,
                        color: Color(0xFFB7B7B7),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.tr('tns.importantNotice'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Calibri',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Text(
                    l10n.tr('tns.insureinfotext'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Calibri',
                      color: Color(0xFF555555),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddInvestmentForm() async {
    final created = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.investment,
      repository: widget.contractsRepository,
    );
    if (!mounted || created != true) return;
    await _reloadContractsAfterDelete();
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }

  String _formatInvestmentType(String? value) {
    if (value == null || value.isEmpty) return '-';
    final translated = context.l10n.trBestEffort(value);
    if (translated != value) {
      return translated;
    }
    return value
        .toLowerCase()
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _formatAmount(double value) {
    final absValue = value.abs();
    final parts = absValue.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    final result = '$intPart,${parts[1]}';
    return 'â‚¬ ${value < 0 ? '-' : ''}$result';
  }
}

bool? _readBoolLike(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

class _ContractsSectionHeader extends StatelessWidget {
  const _ContractsSectionHeader({
    required this.label,
    this.countLabel = '0',
    this.showActions = false,
    this.onInfoTap,
    this.onAddTap,
  });

  final String label;
  final String countLabel;
  final bool showActions;
  final VoidCallback? onInfoTap;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label ($countLabel)',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Calibri',
            fontWeight: FontWeight.w700,
            color: Color(0xFF6C6C6C),
          ),
        ),
        if (showActions)
          Row(
            children: [
              if (onInfoTap != null)
                GestureDetector(
                  onTap: onInfoTap,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      FilipIcons.about,
                      size: 24,
                      color: Color(0xFF6C6C6C),
                    ),
                  ),
                ),
              if (onInfoTap != null && onAddTap != null)
                const SizedBox(width: 8),
              if (onAddTap != null)
                GestureDetector(
                  onTap: onAddTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFD5D5D5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 26,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ContractsPromoCard extends StatelessWidget {
  const _ContractsPromoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8D8D8)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/dashboard/filip_explorer_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Container(color: Colors.white.withValues(alpha: 0.78)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x14FFFFFF)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Calibri',
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFA11C36),
                        width: 1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 24,
                        color: const Color(0xFFA11C36),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractsListLoadingState extends StatelessWidget {
  const _ContractsListLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Calibri',
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentContractCard extends StatelessWidget {
  const _InvestmentContractCard({
    required this.contract,
    required this.currentPersonId,
    required this.formatCurrency,
    required this.formatDate,
    required this.formatInvestmentType,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onTap,
  });

  final InvestmentContract contract;
  final String currentPersonId;
  final String Function(double value) formatCurrency;
  final String Function(DateTime? value) formatDate;
  final String Function(String? value) formatInvestmentType;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFilipSource = contract.source == 'FILIP';
    final iconBackground = isFilipSource
        ? const Color(0xFFEEEEEE)
        : const Color(0xFFFFF5F6);
    final iconColor = isFilipSource
        ? const Color(0xFF707070)
        : AppColors.primaryRed;
    final title = (contract.title == null || contract.title == '-')
        ? formatInvestmentType(contract.investmentType)
        : contract.title!;
    final subtitleType = formatInvestmentType(contract.investmentType);
    final amount = contract.displayAmount;
    final showMoreAction =
        (contract.source == 'FILIP' || contract.source == 'KVV') &&
        contract.personId == currentPersonId;
    final showDeleteAction = contract.source == 'FILIP';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    IconData(
                      contract.iconCodePoint,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    size: 26,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Calibri',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitleType,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Calibri',
                                color: Color(0xFF777777),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'â€¢',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFB6B6B6),
                              ),
                            ),
                          ),
                          Text(
                            formatDate(contract.displayDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Calibri',
                              color: Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showMoreAction)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _ContractMoreActionsButton(
                      showDeleteAction: showDeleteAction,
                      onEditTap: onEditTap,
                      onDeleteTap: onDeleteTap,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBFB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: Row(
              children: [
                _PartnerAvatar(label: contract.partnerName),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayPartnerName(contract.partnerName),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Calibri',
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
                Text(
                  amount == null ? '-' : formatCurrency(amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Calibri',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  String _displayPartnerName(String? partnerName) {
    if (partnerName == null ||
        partnerName.trim().isEmpty ||
        partnerName == '-') {
      return '-';
    }
    return partnerName;
  }
}

class _InsureContractCard extends StatelessWidget {
  const _InsureContractCard({
    required this.contract,
    required this.currentPersonId,
    required this.formatCurrency,
    required this.formatDate,
    required this.formatType,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onTap,
    this.endDatePrefix,
  });

  final InsureContract contract;
  final String currentPersonId;
  final String Function(double value) formatCurrency;
  final String Function(DateTime? value) formatDate;
  final String Function(String? value) formatType;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onTap;
  final String? endDatePrefix;

  @override
  Widget build(BuildContext context) {
    final isFilipSource = contract.source == 'FILIP';
    final iconBackground = isFilipSource
        ? const Color(0xFFEEEEEE)
        : const Color(0xFFFFF5F6);
    final iconColor = isFilipSource
        ? const Color(0xFF707070)
        : AppColors.primaryRed;
    final title = (contract.title == null || contract.title == '-')
        ? formatType(contract.type)
        : contract.title!;
    final showMoreAction = contract.personId == currentPersonId;
    final showDeleteAction = contract.source == 'FILIP';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    IconData(
                      contract.iconCodePoint,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    size: 26,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Calibri',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatType(contract.type),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Calibri',
                                color: Color(0xFF777777),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'â€¢',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFB6B6B6),
                              ),
                            ),
                          ),
                          Text(
                            endDatePrefix == null
                                ? formatDate(contract.endDate)
                                : '$endDatePrefix: ${formatDate(contract.endDate)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Calibri',
                              color: Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showMoreAction)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _ContractMoreActionsButton(
                      showDeleteAction: showDeleteAction,
                      onEditTap: onEditTap,
                      onDeleteTap: onDeleteTap,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFBFB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: Row(
              children: [
                _PartnerAvatar(label: contract.partnerName),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayPartnerName(contract.partnerName),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Calibri',
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
                Text(
                  contract.grossPremium == null
                      ? '-'
                      : formatCurrency(contract.grossPremium!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Calibri',
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  String _displayPartnerName(String? partnerName) {
    if (partnerName == null ||
        partnerName.trim().isEmpty ||
        partnerName == '-') {
      return '-';
    }
    return partnerName;
  }
}

class _ContractMoreActionsButton extends StatelessWidget {
  const _ContractMoreActionsButton({
    required this.showDeleteAction,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final bool showDeleteAction;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  Future<void> _openActionsSheet(BuildContext context) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ContractActionSheetItem(
                  icon: const IconData(
                    0xE969,
                    fontFamily: 'filip_at_iconpack_29022024',
                  ),
                  label: l10n.tr('tns.editContract'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onEditTap();
                  },
                ),
                if (showDeleteAction)
                  const Divider(height: 1, color: Color(0xFFE6E6E6)),
                if (showDeleteAction)
                  _ContractActionSheetItem(
                    icon: const IconData(
                      0xE9F9,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    label: l10n.tr('tns.deleteContract'),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDeleteTap();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      onPressed: () => _openActionsSheet(context),
      icon: const Icon(Icons.more_vert, size: 24, color: Color(0xFF9C9C9C)),
    );
  }
}

class _ContractActionSheetItem extends StatelessWidget {
  const _ContractActionSheetItem({
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
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.primaryRed),
            const SizedBox(width: 18),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final initial = (label == null || label!.trim().isEmpty || label == '-')
        ? '?'
        : label!.trim()[0].toUpperCase();
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF00B67A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Calibri',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _OverviewLoadingState extends StatelessWidget {
  const _OverviewLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Calibri',
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
    this.dot = false,
  });

  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Calibri',
            color: Color(0xFF555555),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: valueColor ?? const Color(0xFF3BAF8E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Calibri',
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
                color: (dot ? valueColor : null) ?? const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// â”€â”€ Generic empty contract tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyContractTab extends StatelessWidget {
  const _EmptyContractTab({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          _ContractsSectionHeader(label: l10n.tr(labelKey)),
          const SizedBox(height: 50),
          _EmptyState(message: l10n.tr('tns.noDataAddedYet')),
        ],
      ),
    );
  }
}

// â”€â”€ Shared empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          SelectNetworkIcons.contract,
          size: 44,
          color: Color(0xFFD0D0D0),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Calibri',
            color: Color(0xFF9A9A9A),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

