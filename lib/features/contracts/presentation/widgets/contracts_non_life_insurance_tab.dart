import 'dart:async';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/insure_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contract_detail_page.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_cards.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_delete_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_shared_widgets.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_contract_modal.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class ContractsNonLifeInsuranceTab extends StatefulWidget {
  const ContractsNonLifeInsuranceTab({
    super.key,
    required this.contractsRepository,
    required this.syncNotificationService,
    required this.personIds,
    required this.ownerMembersByPersonId,
    required this.canAddContracts,
  });

  final ContractsRepository contractsRepository;
  final SyncNotificationService syncNotificationService;
  final List<String> personIds;
  final Map<String, ContractsHouseholdMember> ownerMembersByPersonId;
  final bool canAddContracts;

  @override
  State<ContractsNonLifeInsuranceTab> createState() =>
      _ContractsNonLifeInsuranceTabState();
}

class _ContractsNonLifeInsuranceTabState
    extends State<ContractsNonLifeInsuranceTab> {
  late Future<InsureOverview?> _overviewFuture;
  late final StreamSubscription<Map<String, dynamic>>
  _contractSyncSubscription;
  late final StreamSubscription<Map<String, dynamic>>
  _syncCustomerContractSubscription;
  bool _isReloadingContracts = false;
  bool _isRefreshingFromSyncNotification = false;
  bool _isContractSyncComplete = false;
  bool _isSyncCustomerContractComplete = false;
  bool _skipSnackbar = true;
  final ScrollController _scrollController = ScrollController();
  int _pageNumber = 0;
  static const int _pageSize = 30;
  List<InsureContract> _contracts = [];
  int _totalCount = 0;
  String _currentPersonId = '';
  bool _isLoadingMore = false;
  bool _hasMoreContracts = true;
  bool _isInitialLoadingContracts = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
    _loadContracts(reset: true);
    _contractSyncSubscription = widget
        .syncNotificationService
        .contractSyncCompleted
        .stream
        .listen(_handleContractSyncCompleted);
    _syncCustomerContractSubscription = widget
        .syncNotificationService
        .synccustomercontract
        .stream
        .listen(_handleSyncCustomerContractCompleted);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _contractSyncSubscription.cancel();
    _syncCustomerContractSubscription.cancel();
    super.dispose();
  }

  void _loadData({bool triggerSync = true}) {
    final loadGate = triggerSync ? _runSync() : Future<void>.value();
    _overviewFuture = loadGate.then((_) {
      return widget.contractsRepository.fetchNonLifeInsureOverview(
        personIds: widget.personIds,
      );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMoreContracts) {
      _loadContracts();
    }
  }

  Future<void> _loadContracts({bool reset = false}) async {
    if (!reset && (!_hasMoreContracts || _isLoadingMore)) return;
    if (reset) {
      setState(() {
        _pageNumber = 0;
        _contracts = [];
        _hasMoreContracts = true;
        _isInitialLoadingContracts = true;
      });
    }
    setState(() => _isLoadingMore = true);
    try {
      final data = await widget.contractsRepository.fetchNonLifeInsureContracts(
        personIds: widget.personIds,
        pageNumber: _pageNumber,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (data != null) {
          _contracts.addAll(data.contracts);
          _currentPersonId = data.currentPersonId;
          _totalCount = data.totalCount;
          _hasMoreContracts = data.contracts.length == _pageSize;
          _pageNumber++;
        } else {
          _hasMoreContracts = false;
        }
        _isLoadingMore = false;
        _isInitialLoadingContracts = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoadingContracts = false;
        });
      }
    }
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
    setState(() => _isReloadingContracts = true);
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[_overviewFuture]);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isReloadingContracts = false);
    await _loadContracts(reset: true);
  }

  void _handleContractSyncCompleted(Map<String, dynamic> event) {
    _isContractSyncComplete = true;
    _handleSyncCycleCompleted();
  }

  void _handleSyncCustomerContractCompleted(Map<String, dynamic> event) {
    final skipSnackbar = readBoolLike(event['SkipContractSync']);
    if (skipSnackbar != null) {
      _skipSnackbar = skipSnackbar;
    }
    _isSyncCustomerContractComplete = true;
    _handleSyncCycleCompleted();
  }

  void _handleSyncCycleCompleted() {
    if (!mounted ||
        widget.personIds.isEmpty ||
        !_isContractSyncComplete ||
        !_isSyncCustomerContractComplete ||
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
      await Future.wait<dynamic>(<Future<dynamic>>[_overviewFuture]);
    } catch (_) {
      // Preserve the previous render if the post-sync refresh fails.
    }
    if (!mounted) return;
    setState(() {
      _isRefreshingFromSyncNotification = false;
    });

    await _loadContracts(reset: true);

    if (!mounted) return;
    if (!_skipSnackbar) {
      showContractsSnackBar(
        context,
        context.l10n.tr('CONTRACT_SYNC_COMPLETED'),
      );
    }
    _isContractSyncComplete = false;
    _isSyncCustomerContractComplete = false;
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
    final result = await showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Insure',
        contractItemId: contract.itemId,
      ),
    );
    if (!mounted || result == ContractDeleteSheetResult.cancelled) return;
    if (result == ContractDeleteSheetResult.failed) {
      showContractsSnackBar(
        context,
        context.l10n.tr('tns.contractDeleteFailed'),
      );
      return;
    }

    await _reloadContractsAfterDelete();
    if (!mounted) return;
    showContractsSnackBar(context, context.l10n.tr('tns.contractDeleted'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, contractsBottomClearance),
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
                  return ContractsOverviewLoadingState(
                    message: l10n.tr('tns.loading'),
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
                            ContractsOverviewRow(
                              label: l10n.tr('tns.monthlyPremium'),
                              value: data == null
                                  ? '...'
                                  : formatContractCurrency(data.monthlyPremium),
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            ContractsOverviewRow(
                              label: l10n.tr('tns.annualPremium'),
                              value: data == null
                                  ? '...'
                                  : formatContractCurrency(data.annualPremium),
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
          Builder(
            builder: (context) {
              final countLabel = _isInitialLoadingContracts
                  ? '...'
                  : _totalCount.toString();

              return Column(
                children: [
                  ContractsSectionHeader(
                    label: l10n.tr('tns.insuranceContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: _showAddInsuranceForm,
                    isAddEnabled:
                        widget.canAddContracts && !_isInitialLoadingContracts,
                  ),
                  const SizedBox(height: 14),
                  if (_isInitialLoadingContracts || _isReloadingContracts)
                    ContractsListLoadingState(message: l10n.tr('tns.loading'))
                  else if (_contracts.isEmpty)
                    ContractsEmptyState(
                      message: context.l10n.tr('tns.noDataAddedYet'),
                    )
                  else
                    Column(
                      children: [
                        ...List<Widget>.generate(
                          _contracts.length,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index == _contracts.length - 1 ? 0 : 12,
                            ),
                            child: ContractsInsureContractCard(
                              contract: _contracts[index],
                              currentPersonId: _currentPersonId,
                              ownerMembersByPersonId:
                                  widget.ownerMembersByPersonId,
                              formatCurrency: formatContractCurrency,
                              formatDate: _formatDate,
                              formatType: _formatType,
                              onEditTap: () =>
                                  _handleEditAction(_contracts[index]),
                              onDeleteTap: () =>
                                  _handleDeleteAction(_contracts[index]),
                              onTap: () async {
                                await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ContractDetailPage.fromInsure(
                                          contract: _contracts[index],
                                          entityName: 'Insure',
                                          contractsRepository:
                                              widget.contractsRepository,
                                          currentPersonId: _currentPersonId,
                                        ),
                                  ),
                                );
                                if (mounted) {
                                  await _reloadContractsAfterDelete();
                                }
                              },
                            ),
                          ),
                        ),
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFFD91F32),
                              ),
                            ),
                          ),
                      ],
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
