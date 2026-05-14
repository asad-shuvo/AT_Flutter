import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/insure_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/presentation/contract_detail_page.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_cards.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_delete_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_shared_widgets.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_contract_modal.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:flutter/material.dart';

class ContractsLoanTab extends StatefulWidget {
  const ContractsLoanTab({
    super.key,
    required this.contractsRepository,
    required this.personIds,
    required this.ownerMembersByPersonId,
    required this.canAddContracts,
  });

  final ContractsRepository contractsRepository;
  final List<String> personIds;
  final Map<String, ContractsHouseholdMember> ownerMembersByPersonId;
  final bool canAddContracts;

  @override
  State<ContractsLoanTab> createState() => _ContractsLoanTabState();
}

class _ContractsLoanTabState extends State<ContractsLoanTab> {
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
    final result = await showContractDeleteBottomSheet(
      context,
      onConfirmDelete: () => widget.contractsRepository.deleteContract(
        contractEntityName: 'Loan',
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
                              label: l10n.tr('tns.monthlyPayment'),
                              value: data == null
                                  ? '...'
                                  : formatContractCurrency(data.monthlyPremium),
                              valueBold: true,
                            ),
                            const SizedBox(height: 4),
                            ContractsOverviewRow(
                              label: l10n.tr('tns.yearlyPayment'),
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
          ContractsPromoCard(
            title: l10n.tr('tns.realEstateOverview'),
            subtitle: l10n.tr('tns.realEstateOverviewBody'),
            icon: FilipIcons.loan,
          ),
          const SizedBox(height: 12),
          FutureBuilder<InsureContractsData?>(
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
                    label: l10n.tr('tns.loanContracts'),
                    countLabel: countLabel,
                    showActions: true,
                    onInfoTap: _showInfoSheet,
                    onAddTap: _showAddLoanForm,
                    isAddEnabled: widget.canAddContracts,
                  ),
                  const SizedBox(height: 14),
                  if (isLoadingContracts)
                    ContractsListLoadingState(
                      message: l10n.tr('tns.loading'),
                    )
                  else if (contractsData == null ||
                      contractsData.contracts.isEmpty)
                    ContractsEmptyState(message: l10n.tr('tns.noDataAddedYet'))
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
                          child: ContractsInsureContractCard(
                            contract: contractsData.contracts[index],
                            currentPersonId: contractsData.currentPersonId,
                            ownerMembersByPersonId:
                                widget.ownerMembersByPersonId,
                            formatCurrency: formatContractCurrency,
                            formatDate: _formatDate,
                            formatType: _formatType,
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
                                      ContractDetailPage.fromInsure(
                                        contract:
                                            contractsData.contracts[index],
                                        entityName: 'Loan',
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

  Future<void> _showAddLoanForm() async {
    final created = await showContractsAddContractModal(
      context,
      kind: ContractsAddKind.loan,
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
