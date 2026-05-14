import 'dart:async';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_overview_model.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contract_detail_page.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_cards.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_delete_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_shared_widgets.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_contract_modal.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class ContractsInvestmentTab extends StatefulWidget {
  const ContractsInvestmentTab({
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
  State<ContractsInvestmentTab> createState() =>
      _ContractsInvestmentTabState();
}

class _ContractsInvestmentTabState extends State<ContractsInvestmentTab> {
  late Future<InvestmentOverview?> _overviewFuture;
  late Future<InvestmentContractsData?> _contractsFuture;
  late final StreamSubscription<Map<String, dynamic>>
  _investmentContractSyncSubscription;
  late final StreamSubscription<Map<String, dynamic>>
  _contractSyncSubscription;
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
    final skipSnackbar = readBoolLike(event['SkipContractSync']);
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
      showContractsSnackBar(
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
        syncDisabledProperties: contract.syncDisabledProperties,
      ),
    );
    if (!mounted || updated != true) return;
    await _reloadContractsAfterDelete();
  }

  Future<void> _handleDeleteAction(InvestmentContract contract) async {
    final result = await showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Investment',
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, contractsBottomClearance),
      child: Column(
        children: [
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
                  return ContractsOverviewLoadingState(
                    message: l10n.tr('tns.loading'),
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
                                ContractsOverviewRow(
                                  label: l10n.tr('tns.personalPerformance'),
                                  value: data == null
                                      ? '...'
                                      : data.personalPerformance != null
                                      ? '${data.personalPerformance!.toStringAsFixed(2).replaceAll('.', ',')}%'
                                      : 'N/A',
                                ),
                                const SizedBox(height: 4),
                                ContractsOverviewRow(
                                  label: l10n.tr('tns.totalInvestment'),
                                  value: data == null
                                      ? '...'
                                      : data.totalInvestment != null
                                      ? formatContractCurrency(
                                          data.totalInvestment!,
                                        )
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
                            ContractsOverviewRow(
                              label: l10n.tr('tns.investmentRisk'),
                              value: data.investmentRisk ?? '-',
                              valueColor: const Color(0xFF3BAF8E),
                              valueBold: true,
                              dot: true,
                            ),
                            const SizedBox(height: 4),
                            ContractsOverviewRow(
                              label: l10n.tr('tns.investorProfile'),
                              value: data.investorProfile ?? '-',
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            ContractsOverviewRow(
                              label: l10n.tr('tns.moneyMarketAccount'),
                              value: data.moneyMarketAccount != null
                                  ? formatContractCurrency(
                                      data.moneyMarketAccount!,
                                    )
                                  : '-',
                            ),
                            const SizedBox(height: 4),
                            ContractsOverviewRow(
                              label: l10n.tr('tns.clearingAccount'),
                              value: data.clearingAccount != null
                                  ? formatContractCurrency(
                                      data.clearingAccount!,
                                    )
                                  : '-',
                            ),
                            const SizedBox(height: 4),
                            ContractsOverviewRow(
                              label: l10n.tr('tns.fixedDepositAccounts'),
                              value: data.fixedDepositAccounts != null
                                  ? formatContractCurrency(
                                      data.fixedDepositAccounts!,
                                    )
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
                        onPressed: () =>
                            setState(() => _expanded = !_expanded),
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

          ContractsPromoCard(
            title: l10n.tr('tns.investmentDetails'),
            subtitle: l10n.tr('tns.investmentDetailsSubtitle'),
            icon: SelectNetworkIcons.linkConnect,
          ),

          const SizedBox(height: 12),

          FutureBuilder<InvestmentContractsData?>(
            future: _contractsFuture,
            builder: (context, snapshot) {
              final contractsData =
                  _isReloadingContracts ? null : snapshot.data;
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
                  ContractsSectionHeader(
                    label: l10n.tr('tns.investmentContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: _showAddInvestmentForm,
                    isAddEnabled: widget.canAddContracts,
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingContracts)
                    ContractsListLoadingState(
                      message: l10n.tr('tns.loading'),
                    )
                  else if (contractsData == null ||
                      contractsData.contracts.isEmpty)
                    ContractsEmptyState(
                      message: context.l10n.tr('tns.noDataAddedYet'),
                    )
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
                          child: ContractsInvestmentContractCard(
                            contract: contractsData.contracts[index],
                            currentPersonId: contractsData.currentPersonId,
                            ownerMembersByPersonId:
                                widget.ownerMembersByPersonId,
                            formatCurrency: formatContractCurrency,
                            formatDate: _formatDate,
                            formatInvestmentType: _formatInvestmentType,
                            onEditTap: () =>
                                _handleEditAction(contractsData.contracts[index]),
                            onDeleteTap: () => _handleDeleteAction(
                              contractsData.contracts[index],
                            ),
                            onTap: () async {
                              final edited = await Navigator.of(
                                context,
                              ).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ContractDetailPage.fromInvestment(
                                        contract:
                                            contractsData.contracts[index],
                                        contractsRepository:
                                            widget.contractsRepository,
                                        currentPersonId:
                                            contractsData.currentPersonId,
                                      ),
                                ),
                              );
                              if (edited == true && mounted) {
                                await _reloadContractsAfterDelete();
                              }
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
}
