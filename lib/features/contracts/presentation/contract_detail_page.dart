import 'dart:async';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/insure_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_contract_modal.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contract_document_add_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ContractDetailPage extends StatefulWidget {
  const ContractDetailPage._({
    required this.itemId,
    required this.entityName,
    required this.title,
    required this.iconCodePoint,
    required this.contractsRepository,
    required this.currentPersonId,
    this.notes,
    this.lastUpdateDate,
    this.insureContract,
    this.investmentContract,
  });

  factory ContractDetailPage.fromInsure({
    required InsureContract contract,
    required String entityName,
    required ContractsRepository contractsRepository,
    required String currentPersonId,
  }) {
    return ContractDetailPage._(
      itemId: contract.itemId,
      entityName: entityName,
      title: contract.title ?? contract.type ?? entityName,
      iconCodePoint: contract.iconCodePoint,
      contractsRepository: contractsRepository,
      currentPersonId: currentPersonId,
      notes: contract.notes,
      lastUpdateDate: contract.lastUpdateDate,
      insureContract: contract,
    );
  }

  factory ContractDetailPage.fromInvestment({
    required InvestmentContract contract,
    required ContractsRepository contractsRepository,
    required String currentPersonId,
  }) {
    return ContractDetailPage._(
      itemId: contract.itemId,
      entityName: 'Investment',
      title: contract.title ?? contract.investmentType ?? 'Investment',
      iconCodePoint: contract.iconCodePoint,
      contractsRepository: contractsRepository,
      currentPersonId: currentPersonId,
      notes: contract.notes,
      lastUpdateDate: contract.lastUpdateDate,
      investmentContract: contract,
    );
  }

  final String itemId;
  final String entityName;
  final String title;
  final int iconCodePoint;
  final String? notes;
  final DateTime? lastUpdateDate;
  final InsureContract? insureContract;
  final InvestmentContract? investmentContract;
  final ContractsRepository contractsRepository;
  final String currentPersonId;

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  List<ContractDocument>? _documents;
  bool _docsExpanded = false;
  bool _notesExpanded = false;
  bool _overviewExpanded = true;
  bool _docsLoading = true;
  bool _notesSaving = false;
  bool _editedAtLeastOnce = false;
  String? _optimisticNotes;
  bool _retirementDetailsLoading = false;
  final List<bool> _insuranceModuleExpanded = <bool>[];
  bool _portfolioFundsExpanded = false;
  bool _documentsAdding = false;

  // Holds fresh contract data fetched after an edit.
  Map<String, dynamic>? _freshDetails;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
    if (_isRetirement) {
      unawaited(_refreshContractDetails());
    }
    final initialNotes = widget.notes;
    if (initialNotes != null && initialNotes.isNotEmpty) {
      _notesExpanded = true;
    }
  }

  Future<void> _fetchDocuments() async {
    try {
      final docs = await widget.contractsRepository.fetchContractDocuments(
        contractItemId: widget.itemId,
      );
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _docsLoading = false;
        if (docs.isNotEmpty) _docsExpanded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _documents = const <ContractDocument>[];
        _docsLoading = false;
      });
    }
  }

  // ── helpers that prefer fresh API data ──────────────────────────────────

  String? _fresh(String key) {
    final d = _freshDetails;
    if (d == null) return null;
    final v = d[key];
    if (v == null) return null;
    return v.toString();
  }

  DateTime? _freshDate(String key) {
    final v = _fresh(key);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  double? _freshDouble(String key) {
    final v = _fresh(key);
    if (v == null) return null;
    return double.tryParse(v.replaceAll(',', ''));
  }

  String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  bool get _isEditable {
    final personId = widget.investmentContract?.personId ??
        widget.insureContract?.personId;
    if (personId != widget.currentPersonId) return false;
    if (widget.investmentContract != null) {
      final src = widget.investmentContract!.source;
      return src == 'FILIP' || src == 'KVV';
    }
    return true;
  }

  bool get _isNoteEditable {
    final personId = widget.investmentContract?.personId ??
        widget.insureContract?.personId;
    return personId == widget.currentPersonId;
  }

  bool get _useSyncedNoteUpdate {
    final source = widget.investmentContract?.source ?? widget.insureContract?.source;
    return source != null && source != 'FILIP';
  }

  bool get _hasInsuranceModules {
    return _retirementInsuranceModules.isNotEmpty;
  }

  bool get _hasPortfolioFunds {
    return _retirementPortfolioFunds.isNotEmpty;
  }

  List<_RetirementInsuranceModuleData> get _retirementInsuranceModules {
    final source = _retirementDetailsData();
    final raw = source?['InsuranceModules'];
    if (raw is! List) return const <_RetirementInsuranceModuleData>[];

    return raw
        .whereType<Map>()
        .map(
          (item) => _RetirementInsuranceModuleData(
            division: _readString(item['Division']),
            grossPremium: _readDouble(item['SparteGrossPremium']),
            modules: _readRetirementModuleItems(item['Modules']),
          ),
        )
        .toList(growable: false);
  }

  List<_RetirementModuleItemData> _readRetirementModuleItems(dynamic raw) {
    if (raw is! List) return const <_RetirementModuleItemData>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => _RetirementModuleItemData(
            name: _readString(item['Name']),
            type: _readString(item['Type']),
          ),
        )
        .toList(growable: false);
  }

  List<_RetirementPortfolioFundData> get _retirementPortfolioFunds {
    final source = _retirementDetailsData();
    final raw = source?['Funds'];
    if (raw is! List) return const <_RetirementPortfolioFundData>[];

    return raw
        .whereType<Map>()
        .map(
          (item) => _RetirementPortfolioFundData(
            name: _readString(item['Name']),
            value: _readDouble(item['Value']),
            date: _readDateTime(item['Date']),
          ),
        )
        .toList(growable: false);
  }

  double? get _retirementPortfolioTotalValue {
    return _readDouble(_retirementDetailsData()?['TotalPortfolioValue']);
  }

  Map<String, dynamic>? _retirementDetailsData() {
    if (!_isRetirement) return _freshDetails;
    final current = _freshDetails;
    if (current == null) return null;
    return current;
  }

  void _syncRetirementAccordionState() {
    if (!_isRetirement) return;
    final modules = _retirementInsuranceModules;
    while (_insuranceModuleExpanded.length < modules.length) {
      _insuranceModuleExpanded.add(false);
    }
    if (_insuranceModuleExpanded.length > modules.length) {
      _insuranceModuleExpanded.removeRange(modules.length, _insuranceModuleExpanded.length);
    }
  }

  void _applyLocalNoteUpdate(String? note) {
    setState(() {
      _optimisticNotes = note;
      _notesExpanded = note != null && note.trim().isNotEmpty;
      _editedAtLeastOnce = true;
    });
  }

  // Current values — fresh data takes precedence over original contract.
  String? get _notes {
    if (_optimisticNotes != null) return _optimisticNotes;
    if (_freshDetails != null) return _fresh('Notes');
    return widget.notes;
  }

  DateTime? get _lastUpdateDate {
    if (_freshDetails != null) return _freshDate('LastUpdateDate');
    return widget.lastUpdateDate;
  }

  // InsureContract field accessors (prefer fresh)
  String? _ic(String key) {
    if (_freshDetails != null) return _fresh(key);
    switch (key) {
      case 'ContractNumber':
        return widget.insureContract?.contractNumber;
      case 'Type':
        return widget.insureContract?.type;
      case 'PremiumFrequency':
        return widget.insureContract?.premiumFrequency;
      case 'GrossPremium':
        return widget.insureContract?.grossPremium?.toString();
      case 'Source':
        return widget.insureContract?.source;
      case 'StartDate':
        return widget.insureContract?.startDate?.toIso8601String();
      case 'EndDate':
        return widget.insureContract?.endDate?.toIso8601String();
      case 'DueDate':
        return widget.insureContract?.dueDate?.toIso8601String();
      case 'Status':
        return widget.insureContract?.status;
      case 'PartnerName':
        return widget.insureContract?.partnerName;
      case 'MaturityBenefits':
        return widget.insureContract?.maturityBenefits?.toString();
      default:
        return null;
    }
  }

  // InvestmentContract field accessors (prefer fresh)
  String? _inv(String key) {
    if (_freshDetails != null) return _fresh(key);
    switch (key) {
      case 'InvestmentType':
        return widget.investmentContract?.investmentType;
      case 'PartnerName':
        return widget.investmentContract?.partnerName;
      case 'AccountNumber':
        return widget.investmentContract?.accountNumber;
      case 'ContractNumber':
        return widget.investmentContract?.contractNumber;
      case 'InvestmentStartDate':
        return widget.investmentContract?.investmentStartDate?.toIso8601String();
      case 'InvestmentEndDate':
        return widget.investmentContract?.investmentEndDate?.toIso8601String();
      case 'InvestmentBookValue':
        return widget.investmentContract?.investmentBookValue?.toString();
      case 'InvestmentCurrentValue':
        return widget.investmentContract?.investmentCurrentValue?.toString();
      case 'PaymentFrequency':
        return widget.investmentContract?.paymentFrequency;
      case 'ISIN':
        return widget.investmentContract?.isin;
      default:
        return null;
    }
  }

  // ── formatting ─────────────────────────────────────────────────────────

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final d = DateTime.tryParse(iso);
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String _formatDateDt(DateTime? d) {
    if (d == null) return '-';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String _formatLastUpdate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return 'Last Update On ${date.day}. ${months[date.month - 1]} ${date.year}  at  $hh:$mm o\'clock';
  }

  String _formatCurrency(String? raw) {
    final v = raw == null ? null : double.tryParse(raw.replaceAll(',', ''));
    if (v == null) return '-';
    final abs = v.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    final result = '€ $intPart,${parts[1]}';
    return v < 0 ? '- $result' : result;
  }

  String _formatCurrencyValue(double? value) {
    if (value == null) return '-';
    return _formatCurrency(value.toString());
  }

  bool get _isRetirement => widget.entityName == 'Retirement';
  bool get _isInvestment => widget.entityName == 'Investment';

  // ── edit flow ───────────────────────────────────────────────────────────

  ContractsAddKind get _addKind {
    switch (widget.entityName) {
      case 'Retirement':
        return ContractsAddKind.retirement;
      case 'Loan':
        return ContractsAddKind.loan;
      case 'Investment':
        return ContractsAddKind.investment;
      default:
        return ContractsAddKind.insurance;
    }
  }

  String get _apiEntityName {
    switch (widget.entityName) {
      case 'Investment':
        return 'Investment';
      case 'Loan':
        return 'Loan';
      default:
        return 'Insure';
    }
  }

  ContractsAddInitialData _buildInitialData() {
    if (_isInvestment) {
      final d = _freshDetails;
      final c = widget.investmentContract;
      return ContractsAddInitialData(
        isEdit: true,
        contractId: widget.itemId,
        title: d != null ? _fresh('Title') : c?.title,
        typeValueOrLabel: d != null ? _fresh('InvestmentType') : c?.investmentType,
        partnerName: d != null ? _fresh('PartnerName') : c?.partnerName,
        contractNumber: d != null ? _fresh('ContractNumber') : c?.contractNumber,
        accountNumber: d != null ? _fresh('AccountNumber') : c?.accountNumber,
        bookValue: d != null
            ? _freshDouble('InvestmentBookValue')?.toString()
            : c?.investmentBookValue?.toString(),
        currentValue: d != null
            ? _freshDouble('InvestmentCurrentValue')?.toString()
            : c?.investmentCurrentValue?.toString(),
        lumpSumInvestment: d != null
            ? _freshDouble('LumpSumInvestment')?.toString()
            : c?.lumpSumInvestment?.toString(),
        notes: _notes,
        startDate: d != null ? _freshDate('StartDate') : c?.investmentStartDate,
        endDate: d != null ? _freshDate('EndDate') : c?.investmentEndDate,
        bookValueDate: d != null ? _freshDate('BookValueDate') : c?.bookValueDate,
        currentValueDate: d != null
            ? _freshDate('CurrentValueDate')
            : c?.currentValueDate,
        bondPriceDate: d != null ? _freshDate('BondPriceDate') : c?.bondPriceDate,
        isin: d != null ? _fresh('ISIN') : c?.isin,
        risk: d != null
            ? _freshDouble('Risk')?.toString()
            : c?.risk?.toString(),
        numberOfShares: d != null
            ? _freshDouble('NumberofShares')?.toString()
            : c?.numberOfShares?.toString(),
        currentShareValue: d != null
            ? _freshDouble('CurrentShareValue')?.toString()
            : c?.currentShareValue?.toString(),
        interestRate: d != null
            ? _freshDouble('InterestRate')?.toString()
            : c?.interestRate?.toString(),
        couponRate: d != null
            ? _freshDouble('CouponRate')?.toString()
            : c?.couponRate?.toString(),
        couponTypeValueOrLabel: d != null ? _fresh('CouponType') : c?.couponType,
        couponPeriodValueOrLabel: d != null ? _fresh('CouponPeriod') : c?.couponType,
        currencyValueOrLabel: d != null ? _fresh('Currency') : c?.currency,
        issuer: d != null ? _fresh('Issuer') : c?.issuer,
        bondPrice: d != null
            ? _freshDouble('BondPrice')?.toString()
            : c?.bondPrice?.toString(),
        iban: d != null ? _fresh('IBAN') : c?.iban,
        bic: d != null ? _fresh('BIC') : c?.bic,
        paymentFrequencyValueOrLabel:
            d != null ? _fresh('PaymentFrequency') : c?.paymentFrequency,
        isTargetSumSavingsPlan: d != null
            ? (d['IsTargetSumSavingsPlan'] is bool
                ? d['IsTargetSumSavingsPlan'] as bool
                : null)
            : c?.isTargetSumSavingsPlan,
        isPremiumBenefit: d != null
            ? (d['IsPremiumBenefit'] is bool
                ? d['IsPremiumBenefit'] as bool
                : null)
            : c?.isPremiumBenefit,
        syncDisabledProperties: c?.syncDisabledProperties,
      );
    }

    // InsureContract (insurance / retirement / loan)
    final d = _freshDetails;
    final c = widget.insureContract;
    if (widget.entityName == 'Loan') {
      return ContractsAddInitialData(
        isEdit: true,
        contractId: widget.itemId,
        title: d != null ? _fresh('Title') : c?.title,
        typeValueOrLabel: d != null ? _fresh('Type') : c?.type,
        partnerName: d != null ? _fresh('PartnerName') : c?.partnerName,
        contractNumber: d != null ? _fresh('ContractNumber') : c?.contractNumber,
        loanAmount: d != null
            ? (_freshDouble('Amount') ?? _freshDouble('GrossPremium'))?.toString()
            : c?.grossPremium?.toString(),
        tradeInValue: d != null
            ? _freshDouble('ValueOfTradeIn')?.toString()
            : c?.maturityBenefits?.toString(),
        startDate: d != null ? _freshDate('StartDate') : c?.startDate,
        endDate: d != null ? _freshDate('EndDate') : c?.endDate,
        startOfRepayment: d != null ? _freshDate('StartOfRepayment') : c?.startDate,
        remainingDebtDate: d != null ? _freshDate('DateOfReaminingDept') : c?.dueDate,
        remainingAmount: d != null
            ? _freshDouble('RemainingAmount')?.toString()
            : c?.grossPremium?.toString(),
        notes: _notes,
        status: d != null ? _fresh('Status') : c?.status,
        syncDisabledProperties: c?.syncDisabledProperties,
      );
    }

    return ContractsAddInitialData(
      isEdit: true,
      contractId: widget.itemId,
      title: d != null ? _fresh('Title') : c?.title,
      typeValueOrLabel: d != null ? _fresh('Type') : c?.type,
      partnerName: d != null ? _fresh('PartnerName') : c?.partnerName,
      grossPremium: d != null
          ? _freshDouble('GrossPremium')?.toString()
          : c?.grossPremium?.toString(),
      endDate: d != null ? _freshDate('EndDate') : c?.endDate,
      contractNumber: d != null ? _fresh('ContractNumber') : c?.contractNumber,
      startDate: d != null ? _freshDate('StartDate') : c?.startDate,
      premiumFrequencyValueOrLabel:
          d != null ? _fresh('PremiumFrequency') : c?.premiumFrequency,
      insuranceAmount: d != null
          ? _freshDouble('MaturityBenefits')?.toString()
          : c?.maturityBenefits?.toString(),
      notes: _notes,
      status: d != null ? _fresh('Status') : c?.status,
      dueDate: _isRetirement
          ? (d != null ? _freshDate('DueDate') : c?.dueDate)
          : null,
      syncDisabledProperties: c?.syncDisabledProperties,
    );
  }

  Future<void> _handleEdit() async {
    final updated = await showContractsAddContractModal(
      context,
      kind: _addKind,
      repository: widget.contractsRepository,
      initialData: _buildInitialData(),
    );
    if (!mounted || updated != true) return;

    try {
      await _refreshContractDetails();
    } catch (_) {
      if (!mounted) return;
      setState(() => _editedAtLeastOnce = true);
    }
  }

  Future<void> _refreshContractDetails() async {
    if (_isRetirement && mounted) {
      setState(() => _retirementDetailsLoading = true);
    }

    final fresh = _isRetirement
        ? await widget.contractsRepository.fetchRetirementContractDetails(
            contractItemId: widget.itemId,
            personId: widget.insureContract?.personId ?? widget.currentPersonId,
          )
        : await widget.contractsRepository.fetchContractDetails(
            contractEntityName: _apiEntityName,
            contractItemId: widget.itemId,
          );
    if (!mounted) return;
    setState(() {
      _freshDetails = fresh ?? _freshDetails;
      if (fresh != null) {
        _optimisticNotes = null;
      }
      _editedAtLeastOnce = true;
      _syncRetirementAccordionState();
      final freshNotes = _notes;
      _notesExpanded = freshNotes != null && freshNotes.trim().isNotEmpty;
      _retirementDetailsLoading = false;
    });
  }

  Future<void> _handleAddOrEditNote() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ContractNoteEditorSheet(
        title: context.l10n.tr(
          (_notes?.trim().isNotEmpty ?? false) ? 'tns.editNOTE' : 'tns.addNOTE',
        ),
        initialValue: _notes ?? '',
        isSubmitting: _notesSaving,
        onSubmit: _saveNote,
      ),
    );

    if (saved == true && mounted) {
      await _refreshContractDetails();
    }
  }

  Future<void> _saveNote(String value) async {
    if (_notesSaving) return;
    final previousNotes = _notes;
    FocusScope.of(context).unfocus();
    setState(() => _notesSaving = true);
    _applyLocalNoteUpdate(value.trim());
    try {
      await widget.contractsRepository.updateContractNote(
        entityName: _apiEntityName,
        contractItemId: widget.itemId,
        notes: value.trim(),
        useSyncedUpdate: _useSyncedNoteUpdate,
      );
      if (mounted) {
        unawaited(_refreshContractDetails());
      }
    } catch (_) {
      if (mounted) _showNoteUpdateError();
      if (mounted) {
        setState(() {
          _optimisticNotes = previousNotes;
        });
      }
      if (mounted) {
        unawaited(_refreshContractDetails());
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _notesSaving = false);
      }
    }
  }

  Future<void> _handleDeleteNote() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _NoteDeleteConfirmSheet(),
    );
    if (confirmed != true || !mounted || _notesSaving) return;

    final previousNotes = _notes;
    setState(() => _notesSaving = true);
    _applyLocalNoteUpdate('');
    try {
      await widget.contractsRepository.updateContractNote(
        entityName: _apiEntityName,
        contractItemId: widget.itemId,
        notes: '',
        useSyncedUpdate: _useSyncedNoteUpdate,
      );
      if (!mounted) return;
      unawaited(_refreshContractDetails());
    } catch (_) {
      if (mounted) _showNoteUpdateError();
      if (mounted) {
        setState(() {
          _optimisticNotes = previousNotes;
        });
      }
      if (mounted) {
        unawaited(_refreshContractDetails());
      }
    } finally {
      if (mounted) {
        setState(() => _notesSaving = false);
      }
    }
  }

  Future<void> _showNoteActionSheet() async {
    final action = await showModalBottomSheet<_NoteAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _NoteActionSheet(),
    );
    if (!mounted) return;
    switch (action) {
      case _NoteAction.edit:
        await _handleAddOrEditNote();
        break;
      case _NoteAction.delete:
        await _handleDeleteNote();
        break;
      case null:
        break;
    }
  }

  void _showNoteUpdateError() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.tr('tns.noteUpdateFailed'))),
      );
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              IconData(0xE9F2, fontFamily: 'filip_at_iconpack_29022024'),
              color: Color(0xFF333333),
              size: 22,
            ),
            onPressed: () =>
                Navigator.of(context).pop(_editedAtLeastOnce ? true : null),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(),
              const SizedBox(height: 16),
              _buildNotesSection(),
              const SizedBox(height: 16),
              _buildDocumentsSection(),
              if (_isRetirement) ...[
                const SizedBox(height: 16),
                _buildInsuranceModulesSection(),
                const SizedBox(height: 16),
                _buildPortfolioFundsSection(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final isFilipSource =
        (widget.insureContract?.source ?? widget.investmentContract?.source) ==
            'FILIP';
    final iconBg =
        isFilipSource ? const Color(0xFFEEEEEE) : const Color(0xFFFFF5F6);
    final iconColor =
        isFilipSource ? const Color(0xFF707070) : AppColors.primaryRed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    IconData(
                      widget.iconCodePoint,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    size: 28,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Contract Overview',
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(
                    () => _overviewExpanded = !_overviewExpanded,
                  ),
                  icon: Icon(
                    IconData(
                      _overviewExpanded ? 0xEA33 : 0xEA36,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    size: 20,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(width: 2),
                if (_isEditable)
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: _handleEdit,
                    icon: const Icon(
                      IconData(
                        0xE969,
                        fontFamily: 'filip_at_iconpack_29022024',
                      ),
                      size: 22,
                      color: AppColors.primaryRed,
                    ),
                  ),
              ],
            ),
          ),
          if (_overviewExpanded) ...[
            // Last update row
            if (_lastUpdateDate != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFF2F2F2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  _formatLastUpdate(_lastUpdateDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            // Field rows
            ..._buildFieldRows(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFieldRows() {
    final rows = _isInvestment ? _investmentFields() : _insureFields();
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        result.add(const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Color(0xFFEEEEEE),
        ));
      }
      result.add(rows[i]);
    }
    return result;
  }

  List<Widget> _insureFields() {
    final freqLabel = _isRetirement ? 'Pension Frequency' : 'Premium Frequency';
    final amountLabel = _isRetirement ? 'Insurance Amount' : 'Maturity Benefits';
    return [
      _FieldRow(label: 'Contract Number', value: _ic('ContractNumber')),
      _FieldRow(label: 'Type', value: _ic('Type')),
      _FieldRow(label: freqLabel, value: _ic('PremiumFrequency')),
      _FieldRow(
        label: 'Gross Premium',
        value: _formatCurrency(_ic('GrossPremium')),
      ),
      _FieldRow(label: 'Source', value: _ic('Source')),
      _FieldRow(label: 'Start Date', value: _formatDate(_ic('StartDate'))),
      _FieldRow(label: 'End Date', value: _formatDate(_ic('EndDate'))),
      if (_isRetirement)
        _FieldRow(label: 'Due Date', value: _formatDate(_ic('DueDate'))),
      _FieldRow(label: 'Status', value: _ic('Status')),
      _FieldRow(label: 'Partner', value: _ic('PartnerName')),
      _FieldRow(
        label: amountLabel,
        value: _formatCurrency(_ic('MaturityBenefits')),
      ),
      _FieldRow(label: 'Contract Reference', value: _ic('ContractNumber')),
    ];
  }

  List<Widget> _investmentFields() {
    return [
      _FieldRow(label: 'Investment Type', value: _inv('InvestmentType')),
      _FieldRow(label: 'Partner', value: _inv('PartnerName')),
      _FieldRow(label: 'Account Number', value: _inv('AccountNumber')),
      _FieldRow(label: 'Contract Number', value: _inv('ContractNumber')),
      _FieldRow(
        label: 'Start Date',
        value: _formatDate(_inv('InvestmentStartDate')),
      ),
      _FieldRow(
        label: 'End Date',
        value: _formatDate(_inv('InvestmentEndDate')),
      ),
      _FieldRow(
        label: 'Book Value',
        value: _formatCurrency(_inv('InvestmentBookValue')),
      ),
      _FieldRow(
        label: 'Current Value',
        value: _formatCurrency(_inv('InvestmentCurrentValue')),
      ),
      _FieldRow(
        label: 'Payment Frequency',
        value: _inv('PaymentFrequency'),
      ),
      if (_inv('ISIN') != null) _FieldRow(label: 'ISIN', value: _inv('ISIN')),
    ];
  }

  Widget _buildNotesSection() {
    final currentNotes = _notes;
    final hasNote = currentNotes != null && currentNotes.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            onTap: hasNote
                ? () => setState(() => _notesExpanded = !_notesExpanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    IconData(0xE976, fontFamily: 'filip_at_iconpack_29022024'),
                    size: 22,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  if (hasNote) ...[
                    GestureDetector(
                      onTap: () => setState(() => _notesExpanded = !_notesExpanded),
                      child: Icon(
                        IconData(
                          _notesExpanded ? 0xEA33 : 0xEA36,
                          fontFamily: 'filip_at_iconpack_29022024',
                        ),
                        size: 18,
                        color: _notesSaving
                            ? AppColors.primaryRed.withValues(alpha: 0.45)
                            : AppColors.primaryRed,
                      ),
                    ),
                    if (_isNoteEditable) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _notesSaving ? null : _showNoteActionSheet,
                        child: Icon(
                          Icons.more_vert,
                          size: 22,
                          color: _notesSaving
                              ? AppColors.primaryRed.withValues(alpha: 0.45)
                              : AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ] else
                    if (_isNoteEditable)
                      GestureDetector(
                        onTap: _notesSaving ? null : _handleAddOrEditNote,
                        child: Icon(
                          const IconData(
                            0xE95B,
                            fontFamily: 'filip_at_iconpack_29022024',
                          ),
                          size: 22,
                          color: _notesSaving
                              ? AppColors.primaryRed.withValues(alpha: 0.45)
                              : AppColors.primaryRed,
                        ),
                      ),
                ],
              ),
            ),
          ),
          if (_notesSaving) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const LinearProgressIndicator(
              minHeight: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          ],
          if (hasNote && _notesExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentNotes ?? '',
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docs = _documents ?? const <ContractDocument>[];
    final hasData = docs.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            onTap: hasData
                ? () => setState(() => _docsExpanded = !_docsExpanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    IconData(0xE9DF, fontFamily: 'filip_at_iconpack_29022024'),
                    size: 22,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Important Documents',
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  if (hasData)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        IconData(
                          _docsExpanded ? 0xEA33 : 0xEA36,
                          fontFamily: 'filip_at_iconpack_29022024',
                        ),
                        size: 18,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  GestureDetector(
                    onTap: _documentsAdding ? null : _handleAddDocument,
                    child: Icon(
                      IconData(0xE95B, fontFamily: 'filip_at_iconpack_29022024'),
                      size: 22,
                      color: _documentsAdding
                          ? AppColors.primaryRed.withValues(alpha: 0.45)
                          : AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_docsLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (hasData && _docsExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ...docs.map(
              (doc) => _DocumentRow(
                document: doc,
                formatDate: _formatDateDt,
                onArchiveTap: () => _confirmArchive(doc),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAddDocument() async {
    setState(() => _documentsAdding = true);
    try {
      final result = await showContractDocumentAddSheet(
        context,
        onSubmit: ({
          required String resourceTitle,
          required String? urlAddress,
          required String? uploadedFilePath,
        }) async {
          if (urlAddress != null) {
            await widget.contractsRepository.createExternalLinkDocument(
              contractItemId: widget.itemId,
              resourceTitle: resourceTitle,
              urlAddress: urlAddress,
            );
          } else if (uploadedFilePath != null) {
            await widget.contractsRepository.uploadContractDocument(
              contractItemId: widget.itemId,
              resourceTitle: resourceTitle,
              filePath: uploadedFilePath,
              personId: widget.currentPersonId,
            );
          }
        },
      );

      if (mounted) {
        setState(() => _docsExpanded = true);
        await _fetchDocuments();
      }
    } finally {
      if (mounted) {
        setState(() => _documentsAdding = false);
      }
    }
  }

  Future<void> _confirmArchive(ContractDocument doc) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ArchiveConfirmSheet(),
    );
    if (confirmed == true && mounted) {
      // TODO: call archive API when DocumentManagerService URL is configured
      setState(() {
        _documents =
            _documents?.where((d) => d.itemId != doc.itemId).toList();
      });
    }
  }

  void _toggleInsuranceModule(int index) {
    setState(() {
      if (index >= 0 && index < _insuranceModuleExpanded.length) {
        _insuranceModuleExpanded[index] = !_insuranceModuleExpanded[index];
      }
    });
  }

  void _togglePortfolioFunds() {
    setState(() {
      _portfolioFundsExpanded = !_portfolioFundsExpanded;
    });
  }

  Widget _buildInsuranceModulesSection() {
    final modules = _retirementInsuranceModules;
    final hasData = modules.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  IconData(0xE956, fontFamily: 'filip_at_iconpack_29022024'),
                  size: 28,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Insurance Modules',
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF888888)),
                  ),
                  child: const Center(
                    child: Text(
                      'i',
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 13,
                        color: Color(0xFF888888),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E2E2)),
          if (_retirementDetailsLoading && !hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!hasData)
            _buildRetirementEmptyState()
          else ...[
            ...modules.asMap().entries.map(
              (entry) => _buildInsuranceModuleCard(
                entry.key,
                entry.value,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioFundsSection() {
    final funds = _retirementPortfolioFunds;
    final hasData = funds.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            onTap: hasData ? _togglePortfolioFunds : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    IconData(0xE980, fontFamily: 'filip_at_iconpack_29022024'),
                    size: 28,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Portfolio Funds',
                    style: TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total portfolio Value',
                        style: TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                      Text(
                        _formatCurrencyValue(_retirementPortfolioTotalValue),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    IconData(
                      hasData && _portfolioFundsExpanded ? 0xEA33 : 0xEA36,
                      fontFamily: 'filip_at_iconpack_29022024',
                    ),
                    size: 18,
                    color: AppColors.primaryRed,
                  ),
                ],
              ),
            ),
          ),
          if (_retirementDetailsLoading && !hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!hasData)
            _buildRetirementEmptyState()
          else if (_portfolioFundsExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E2E2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < funds.length; i++) ...[
                    _buildPortfolioFundCard(funds[i]),
                    if (i != funds.length - 1) const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsuranceModuleCard(
    int index,
    _RetirementInsuranceModuleData module,
  ) {
    final expanded = _insuranceModuleExpanded[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _toggleInsuranceModule(index),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPARTE ${index + 1}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Type ${module.division.isEmpty ? '-' : module.division}',
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 15,
                              color: Color(0xFF5A5A5A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Gross Premium',
                          style: TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 14,
                            color: Color(0xFF5A5A5A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatCurrencyValue(module.grossPremium),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      IconData(
                        expanded ? 0xEA33 : 0xEA36,
                        fontFamily: 'filip_at_iconpack_29022024',
                      ),
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1, color: Color(0xFFE2E2E2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  children: [
                    for (var i = 0; i < module.modules.length; i++) ...[
                      _buildRetirementModuleItemRow(i, module.modules[i]),
                      if (i != module.modules.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRetirementModuleItemRow(
    int index,
    _RetirementModuleItemData item,
  ) {
    final details = <String>[
      if (item.name.trim().isNotEmpty) item.name.trim(),
      if (item.type.trim().isNotEmpty) '(${item.type.trim()})',
    ].join(' ');

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            'MODULE ${index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 17,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Text(
            details.isEmpty ? '-' : details,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 17,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioFundCard(_RetirementPortfolioFundData fund) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fund.name.isEmpty ? '-' : fund.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Value (€): ${_formatCurrencyValue(fund.value)}   Date: ${_formatDateDt(fund.date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetirementEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No data found',
          style: TextStyle(
            fontFamily: 'Calibri',
            fontSize: 16,
            color: Color(0xFFC6C6C6),
          ),
        ),
      ),
    );
  }
}

// ── shared widgets ──────────────────────────────────────────────────────────

class _RetirementInsuranceModuleData {
  const _RetirementInsuranceModuleData({
    required this.division,
    required this.grossPremium,
    required this.modules,
  });

  final String division;
  final double? grossPremium;
  final List<_RetirementModuleItemData> modules;
}

class _RetirementModuleItemData {
  const _RetirementModuleItemData({
    required this.name,
    required this.type,
  });

  final String name;
  final String type;
}

class _RetirementPortfolioFundData {
  const _RetirementPortfolioFundData({
    required this.name,
    required this.value,
    required this.date,
  });

  final String name;
  final double? value;
  final DateTime? date;
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty || value == '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              isEmpty ? 'No data found' : value!,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 15,
                color: isEmpty
                    ? const Color(0xFFBBBBBB)
                    : const Color(0xFF333333),
                fontStyle:
                    isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.formatDate,
    required this.onArchiveTap,
  });

  final ContractDocument document;
  final String Function(DateTime?) formatDate;
  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              document.name ?? 'Document',
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
          ),
          Text(
            formatDate(document.uploadDate),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onArchiveTap,
            child: const Icon(
              IconData(0xEA29, fontFamily: 'filip_at_iconpack_29022024'),
              size: 20,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NoteAction { edit, delete }

class _NoteActionSheet extends StatelessWidget {
  const _NoteActionSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NoteActionTile(
              icon: 0xE969,
              label: l10n.tr('tns.editNOTE'),
              onTap: () => Navigator.of(context).pop(_NoteAction.edit),
            ),
            const Divider(height: 1, indent: 18, endIndent: 18),
            _NoteActionTile(
              icon: 0xE9F9,
              label: l10n.tr('tns.deleteNote'),
              onTap: () => Navigator.of(context).pop(_NoteAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteActionTile extends StatelessWidget {
  const _NoteActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
        child: Row(
          children: [
            Icon(
              IconData(icon, fontFamily: 'filip_at_iconpack_29022024'),
              size: 26,
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteDeleteConfirmSheet extends StatelessWidget {
  const _NoteDeleteConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 34, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconData(0xE9F9, fontFamily: 'filip_at_iconpack_29022024'),
                  size: 72,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    l10n.tr('tns.deleteNoteConfirmationMessage'),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD0D0D0)),
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
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractNoteEditorSheet extends StatefulWidget {
  const _ContractNoteEditorSheet({
    required this.title,
    required this.initialValue,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String title;
  final String initialValue;
  final bool isSubmitting;
  final Future<void> Function(String value) onSubmit;

  @override
  State<_ContractNoteEditorSheet> createState() => _ContractNoteEditorSheetState();
}

class _ContractNoteEditorSheetState extends State<_ContractNoteEditorSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) return;
    setState(() {
      _errorText = _validate(_controller.text, context.l10n);
    });
  }

  String? _validate(String value, AppLocalizations l10n) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed.length < 10) {
      return l10n.tr('tns.minimumCharacters', {'count': '10'});
    }
    if (trimmed.length > 300) {
      return l10n.tr('tns.maximumCharacters', {'count': '300'});
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final validationError = _validate(_controller.text, l10n);
    setState(() => _errorText = validationError);
    if (validationError != null || _submitting || widget.isSubmitting) return;

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_controller.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final effectiveSubmitting = _submitting || widget.isSubmitting;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textLength = _controller.text.length;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ContractsAddFormSheet(
        title: widget.title,
        isSubmitting: effectiveSubmitting,
        onSubmit: _submit,
        submitLabel: l10n.tr('tns.save').toUpperCase(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  IconData(0xE976, fontFamily: 'filip_at_iconpack_29022024'),
                  size: 26,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.tr('tns.notes'),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 18,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ContractsFormSectionTitle(l10n.tr('tns.notes')),
            TextField(
              controller: _controller,
              enabled: !effectiveSubmitting,
              maxLength: 300,
              maxLines: 7,
              minLines: 7,
              decoration: InputDecoration(
                hintText: '${l10n.tr('tns.writeTextHere')}...',
                counterText: '$textLength/300',
                errorText: _errorText,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFA11C36)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFA11C36),
                    width: 1.2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryRed),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryRed,
                    width: 1.2,
                  ),
                ),
                hintStyle: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  color: Color(0xFFB5B5B5),
                ),
                counterStyle: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 13,
                  color: Color(0xFF8C8C8C),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveConfirmSheet extends StatelessWidget {
  const _ArchiveConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryRed, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryRed, width: 2),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 2,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Are you sure you want to archive this document?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'CONFIRM',
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
