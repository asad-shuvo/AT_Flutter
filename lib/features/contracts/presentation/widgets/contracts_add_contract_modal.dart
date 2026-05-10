import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ContractsAddKind { insurance, retirement, loan, investment }

Future<bool?> showContractsAddContractModal(
  BuildContext context, {
  required ContractsAddKind kind,
  required ContractsRepository repository,
  ContractsAddInitialData? initialData,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ContractsAddContractModal(
          kind: kind,
          repository: repository,
          initialData: initialData,
        ),
  );
}

class _ContractsAddContractModal extends StatefulWidget {
  const _ContractsAddContractModal({
    required this.kind,
    required this.repository,
    this.initialData,
  });

  final ContractsAddKind kind;
  final ContractsRepository repository;
  final ContractsAddInitialData? initialData;

  @override
  State<_ContractsAddContractModal> createState() =>
      _ContractsAddContractModalState();
}

class _ContractsAddContractModalState
    extends State<_ContractsAddContractModal> {
  late Future<_ContractsAddBootstrapData> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    final isEditMode = widget.initialData?.isEdit == true;
    final cachedTypes = widget.repository.peekContractTypes(
      _lookupEntityName(widget.kind),
    );
    final cachedPartners = widget.repository.peekPartners();

    if (!isEditMode && cachedTypes != null && cachedPartners != null) {
      _bootstrapFuture = SynchronousFuture<_ContractsAddBootstrapData>(
        _ContractsAddBootstrapData(
          types: cachedTypes,
          partners: cachedPartners,
          fullContractDetails: null,
        ),
      );
    } else {
      _bootstrapFuture = _loadBootstrap();
    }
  }

  Future<_ContractsAddBootstrapData> _loadBootstrap() async {
    // ignore: avoid_print
    print('[contracts] Bootstrap started - isEdit=${widget.initialData?.isEdit}, contractId=${widget.initialData?.contractId}');
    
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      widget.repository.fetchContractTypes(_lookupEntityName(widget.kind)),
      widget.repository.fetchPartners(),
      if (widget.initialData?.isEdit == true && widget.initialData?.contractId != null)
        widget.repository.fetchContractDetails(
          contractEntityName: _apiEntityName(widget.kind),
          contractItemId: widget.initialData!.contractId!,
        )
      else
        Future<dynamic>.value(null),
    ]);

    final fullDetails = results.length > 2 ? results[2] as Map<String, dynamic>? : null;
    // ignore: avoid_print
    print('[contracts] Bootstrap complete - fullDetails is ${fullDetails == null ? 'NULL' : 'POPULATED (${fullDetails.keys.length} keys)'}');

    return _ContractsAddBootstrapData(
      types: results[0] as List<ContractsLookupOption>,
      partners: results[1] as List<ContractsPartnerOption>,
      fullContractDetails: fullDetails,
    );
  }

  ContractsAddInitialData? _enrichInitialDataWithFullDetails(
    ContractsAddInitialData? initialData,
    Map<String, dynamic>? fullDetails,
  ) {
    if (initialData == null || fullDetails == null) {
      return initialData;
    }

    return ContractsAddInitialData(
      isEdit: initialData.isEdit,
      contractId: initialData.contractId ?? _readString(fullDetails['ItemId']),
      typeValueOrLabel: initialData.typeValueOrLabel ?? _readString(fullDetails['Type']),
      title: initialData.title ?? _readString(fullDetails['Title']),
      contractNumber: initialData.contractNumber ?? _readString(fullDetails['ContractNumber']),
      partnerName: initialData.partnerName ?? _readString(fullDetails['PartnerName']),
      premiumFrequencyValueOrLabel: initialData.premiumFrequencyValueOrLabel ?? _readString(fullDetails['PremiumFrequency']),
      paymentFrequencyValueOrLabel: initialData.paymentFrequencyValueOrLabel ?? _readString(fullDetails['PaymentFrequency']),
      grossPremium: initialData.grossPremium ?? _readDouble(fullDetails['GrossPremium'])?.toString(),
      insuranceAmount: initialData.insuranceAmount ?? _readDouble(fullDetails['MaturityBenefits'])?.toString(),
      loanAmount: initialData.loanAmount ?? _readDouble(fullDetails['Amount'])?.toString(),
      tradeInValue: initialData.tradeInValue ?? _readDouble(fullDetails['ValueOfTradeIn'])?.toString(),
      accountNumber: initialData.accountNumber ?? _readString(fullDetails['AccountNumber']),
      bookValue: initialData.bookValue ?? _readDouble(fullDetails['InvestmentBookValue'])?.toString(),
      currentValue: initialData.currentValue ?? _readDouble(fullDetails['InvestmentCurrentValue'])?.toString(),
      lumpSumInvestment: initialData.lumpSumInvestment ?? _readDouble(fullDetails['LumpSumInvestment'])?.toString(),
      notes: initialData.notes ?? _readString(fullDetails['Notes']),
      startDate: initialData.startDate ?? _readDateTime(fullDetails['StartDate']),
      endDate: initialData.endDate ?? _readDateTime(fullDetails['EndDate']),
      dueDate: initialData.dueDate ?? _readDateTime(fullDetails['DueDate']),
      bookValueDate: initialData.bookValueDate ?? _readDateTime(fullDetails['BookValueDate']),
      currentValueDate: initialData.currentValueDate ?? _readDateTime(fullDetails['CurrentValueDate']),
      status: initialData.status ?? _readString(fullDetails['Status']),
      isin: initialData.isin ?? _readString(fullDetails['ISIN']),
      currentShareValue: initialData.currentShareValue ?? _readDouble(fullDetails['CurrentShareValue'])?.toString(),
      numberOfShares: initialData.numberOfShares ?? _readDouble(fullDetails['NumberofShares'])?.toString(),
      interestRate: initialData.interestRate ?? _readDouble(fullDetails['InterestRate'])?.toString(),
      couponRate: initialData.couponRate ?? _readDouble(fullDetails['CouponRate'])?.toString(),
      couponTypeValueOrLabel: initialData.couponTypeValueOrLabel ?? _readString(fullDetails['CouponType']),
      couponPeriodValueOrLabel: initialData.couponPeriodValueOrLabel ?? _readString(fullDetails['CouponPeriod']),
      currencyValueOrLabel: initialData.currencyValueOrLabel ?? _readString(fullDetails['Currency']),
      issuer: initialData.issuer ?? _readString(fullDetails['Issuer']),
      bondPrice: initialData.bondPrice ?? _readDouble(fullDetails['BondPrice'])?.toString(),
      bondPriceDate: initialData.bondPriceDate ?? _readDateTime(fullDetails['BondPriceDate']),
      risk: initialData.risk ?? _readDouble(fullDetails['Risk'])?.toString(),
      isTargetSumSavingsPlan: initialData.isTargetSumSavingsPlan ?? (fullDetails['IsTargetSumSavingsPlan'] is bool ? fullDetails['IsTargetSumSavingsPlan'] as bool : null),
      isPremiumBenefit: initialData.isPremiumBenefit ?? (fullDetails['IsPremiumBenefit'] is bool ? fullDetails['IsPremiumBenefit'] as bool : null),
      iban: initialData.iban ?? _readString(fullDetails['IBAN']),
      bic: initialData.bic ?? _readString(fullDetails['BIC']),
      interestTypeValueOrLabel: initialData.interestTypeValueOrLabel ?? _readString(fullDetails['TypeOfInterest']),
      fixedInterestRate: initialData.fixedInterestRate ?? _readDouble(fullDetails['FixedInterestRate'])?.toString(),
      fixedInterestRateDuration: initialData.fixedInterestRateDuration ?? _readInt(fullDetails['FixedInterestRateDuration'])?.toString(),
      referenceRateValueOrLabel: initialData.referenceRateValueOrLabel ?? _readString(fullDetails['ReferenceInterestRate']),
      bankSurcharge: initialData.bankSurcharge ?? _readDouble(fullDetails['BankSurcharge'])?.toString(),
      remainingAmount: initialData.remainingAmount ?? _readDouble(fullDetails['RemainingAmount'])?.toString(),
      remainingDebtDate: initialData.remainingDebtDate ?? _readDateTime(fullDetails['DateOfReaminingDept']),
      startOfRepayment: initialData.startOfRepayment ?? _readDateTime(fullDetails['StartOfRepayment']),
      syncDisabledProperties: initialData.syncDisabledProperties ?? _readStringList(fullDetails['SyncDisabledProperties']),
      isLifeTime: initialData.isLifeTime ?? (fullDetails['IsLifeTime'] is bool ? fullDetails['IsLifeTime'] as bool : null),
    );
  }

  // ignore: unused_element
  void _debugSyncDisabled(Map<String, dynamic>? d) {
    // ignore: avoid_print
    print('[contracts] SyncDisabledProperties raw: ${d?['SyncDisabledProperties']} keys=${d?.keys.toList()}');
  }

  List<String>? _readStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return null;
  }

  String? _readString(dynamic value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return null;
  }

  double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', ''));
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ContractsAddBootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final l10n = context.l10n;
        final title = widget.initialData?.isEdit == true
            ? l10n.tr(_editTitleKey(widget.kind))
            : l10n.tr(_titleKey(widget.kind));
        final submitLabel = widget.initialData?.isEdit == true
            ? l10n.tr('tns.edit')
            : l10n.tr('tns.create');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ContractsAddFormSheet(
            title: title,
            onSubmit: null,
            submitLabel: submitLabel,
            submitEnabled: false,
            showSubmitButton: false,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryRed,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ContractsAddFormSheet(
            title: title,
            onSubmit: () {
              setState(() {
                _bootstrapFuture = _loadBootstrap();
              });
            },
            submitLabel: l10n.tr('common.retry'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.tr('tns.contractFormLoadFailed'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 16,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        _debugSyncDisabled(data.fullContractDetails);
        final enrichedInitialData = _enrichInitialDataWithFullDetails(
          widget.initialData,
          data.fullContractDetails,
        );
        // ignore: avoid_print
        print('[contracts] enriched syncDisabled=${enrichedInitialData?.syncDisabledProperties}');

        switch (widget.kind) {
          case ContractsAddKind.insurance:
            return _InsuranceContractFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
          case ContractsAddKind.retirement:
            return _RetirementContractFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
          case ContractsAddKind.loan:
            return _LoanContractFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
          case ContractsAddKind.investment:
            return _InvestmentContractFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
        }
      },
    );
  }
}

class _InsuranceContractFormModal extends StatefulWidget {
  const _InsuranceContractFormModal({
    required this.repository,
    required this.title,
    required this.submitLabel,
    required this.types,
    required this.partners,
    this.initialData,
  });

  final ContractsRepository repository;
  final String title;
  final String submitLabel;
  final List<ContractsLookupOption> types;
  final List<ContractsPartnerOption> partners;
  final ContractsAddInitialData? initialData;

  @override
  State<_InsuranceContractFormModal> createState() =>
      _InsuranceContractFormModalState();
}

class _InsuranceContractFormModalState
    extends State<_InsuranceContractFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contractNumberController = TextEditingController();
  final _grossPremiumController = TextEditingController();
  final _maturityBenefitsController = TextEditingController();
  final _notesController = TextEditingController();

  ContractsLookupOption? _selectedType;
  ContractsLookupOption? _selectedFrequency;
  ContractsPartnerOption? _selectedPartner;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isLifeTime;
  bool _isSubmitting = false;

  bool get _canSubmitRequiredFields {
    return _selectedType != null &&
        _selectedFrequency != null &&
        _titleController.text.trim().isNotEmpty &&
        _grossPremiumController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _titleController.text = initial.title ?? '';
      _contractNumberController.text = initial.contractNumber ?? '';
      _grossPremiumController.text = initial.grossPremium ?? '';
      _maturityBenefitsController.text = initial.insuranceAmount ?? '';
      _notesController.text = initial.notes ?? '';
      _startDate = initial.startDate;
      _endDate = initial.endDate;
      _isLifeTime = initial.isLifeTime;
      _selectedType = _findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedFrequency = _findLookupByAny(
        _insuranceFrequencyOptions,
        initial.premiumFrequencyValueOrLabel,
      );
      _selectedPartner = _findPartner(widget.partners, initial.partnerName);
    }
    _titleController.addListener(_onRequiredFieldsChanged);
    _grossPremiumController.addListener(_onRequiredFieldsChanged);
  }

  void _onRequiredFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onRequiredFieldsChanged);
    _grossPremiumController.removeListener(_onRequiredFieldsChanged);
    _titleController.dispose();
    _contractNumberController.dispose();
    _grossPremiumController.dispose();
    _maturityBenefitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final contractData = <String, dynamic>{
        'Title': _titleController.text.trim(),
        'ContractNumber': _nullIfBlank(_contractNumberController.text),
        'Type': _selectedType!.label,
        'StartDate': _toIsoDate(_startDate),
        'EndDate': _toIsoDate(_endDate),
        'GrossPremium': _parseNumber(_grossPremiumController.text),
        'PremiumFrequency': _selectedFrequency!.value,
        'MaturityBenefits': _parseNumber(_maturityBenefitsController.text),
        'IsLifeTime': _isLifeTime ?? false,
        'Status': null,
        'Source': 'FILIP',
        'AdviserVisibility': true,
        'PartnerId': _selectedPartner?.itemId,
        'PartnerName': _selectedPartner?.name,
        'PartnerItemId': _selectedPartner?.itemId,
        'ProductPartnerDescription': null,
        'Language': Localizations.localeOf(context).languageCode,
        'Tags': const <String>['Is-A-Insure', 'Is-A-Non-Life-Insure'],
        'Notes': _nullIfBlank(_notesController.text),
      };

      if (widget.initialData?.isEdit == true) {
        contractData['ItemId'] = widget.initialData?.contractId;
        await widget.repository.updateContract(
          contractEntityName: 'Insure',
          contractData: contractData,
        );
      } else {
        await widget.repository.createContract(
          contractEntityName: 'Insure',
          contractData: contractData,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showCreateFailedMessage(context);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;


    return ContractsAddFormSheet(
      title: widget.title,
      onSubmit: _submit,
      submitLabel: widget.submitLabel,
      isSubmitting: _isSubmitting,
      submitEnabled: _canSubmitRequiredFields && !_isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.type'),
              required: true,
              hint: l10n.tr('tns.type'),
              items: widget.types,
              value: _selectedType,
              itemLabel: (item) => _localizedContractTypeLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) => _requiredSelectionValidator(value, l10n),
              enabled: !_isApiDisabledField(widget.initialData, 'Type'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractTitle'),
              required: true,
              controller: _titleController,
              validator: (value) =>
                  _textValidator(value, l10n, required: true, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'Title'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractNumber'),
              controller: _contractNumberController,
              validator: (value) => _textValidator(value, l10n, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'ContractNumber'),
            ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.premiumFrequency'),
              required: true,
              hint: l10n.tr('tns.premiumFrequency'),
              items: _insuranceFrequencyOptions,
              value: _selectedFrequency,
              itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedFrequency = value),
              validator: (value) => _requiredSelectionValidator(value, l10n),
              enabled: !_isApiDisabledField(widget.initialData, 'PremiumFrequency'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.grossPremium'),
              required: true,
              controller: _grossPremiumController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) => _numberValidator(
                value,
                l10n,
                required: true,
                min: 0,
                max: 999999,
              ),
              enabled: !_isApiDisabledField(widget.initialData, 'GrossPremium'),
            ),
            ContractsDropdownField<ContractsPartnerOption>(
              label: l10n.tr('tns.partner'),
              hint: l10n.tr('tns.selectPartner'),
              items: widget.partners,
              value: _selectedPartner,
              itemLabel: (item) => item.name,
              onChanged: (value) => setState(() => _selectedPartner = value),
              enabled: !_isApiDisabledField(widget.initialData, 'PartnerName'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.insuranceAmount'),
              controller: _maturityBenefitsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) =>
                  _numberValidator(value, l10n, min: 0, max: 999999),
              enabled: !_isApiDisabledField(widget.initialData, 'MaturityBenefits'),
            ),
            ContractsDateField(
              label: l10n.tr('tns.startDate'),
              value: _startDate,
              enabled: !_isApiDisabledField(widget.initialData, 'StartDate'),
              onTap: () async {
                final value = await _pickDate(context, _startDate);
                if (value != null) setState(() => _startDate = value);
              },
            ),
            ContractsDateField(
              label: l10n.tr('tns.endDate'),
              value: _endDate,
              enabled: !_isApiDisabledField(widget.initialData, 'EndDate'),
              onTap: () async {
                final value = await _pickDate(context, _endDate);
                if (value != null) setState(() => _endDate = value);
              },
            ),
            ContractsTextField(
              label: l10n.tr('tns.notes'),
              controller: _notesController,
              maxLines: 4,
              validator: (value) =>
                  _textValidator(value, l10n, maxLength: 300),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetirementContractFormModal extends StatefulWidget {
  const _RetirementContractFormModal({
    required this.repository,
    required this.title,
    required this.submitLabel,
    required this.types,
    required this.partners,
    this.initialData,
  });

  final ContractsRepository repository;
  final String title;
  final String submitLabel;
  final List<ContractsLookupOption> types;
  final List<ContractsPartnerOption> partners;
  final ContractsAddInitialData? initialData;

  @override
  State<_RetirementContractFormModal> createState() =>
      _RetirementContractFormModalState();
}

class _RetirementContractFormModalState
    extends State<_RetirementContractFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contractNumberController = TextEditingController();
  final _grossPremiumController = TextEditingController();
  final _notesController = TextEditingController();

  ContractsLookupOption? _selectedType;
  ContractsLookupOption? _selectedFrequency;
  ContractsLookupOption? _selectedStatus;
  ContractsPartnerOption? _selectedPartner;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  bool get _canSubmitRequiredFields {
    return _selectedType != null &&
        _selectedFrequency != null &&
        _titleController.text.trim().isNotEmpty &&
        _grossPremiumController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _titleController.text = initial.title ?? '';
      _contractNumberController.text = initial.contractNumber ?? '';
      _grossPremiumController.text = initial.grossPremium ?? '';
      _notesController.text = initial.notes ?? '';
      _startDate = initial.startDate;
      _endDate = initial.endDate;
      _dueDate = initial.dueDate;
      _selectedType = _findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedFrequency = _findLookupByAny(
        _retirementFrequencyOptions,
        initial.premiumFrequencyValueOrLabel,
      );
      _selectedPartner = _findPartner(widget.partners, initial.partnerName);
    }
    _titleController.addListener(_onRequiredFieldsChanged);
    _grossPremiumController.addListener(_onRequiredFieldsChanged);
  }

  bool _statusResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_statusResolved) {
      _statusResolved = true;
      final initial = widget.initialData;
      if (initial != null) {
        _selectedStatus = _findLookupByAny(
          _retirementStatusOptions(context.l10n),
          initial.status,
        );
      }
    }
  }

  void _onRequiredFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onRequiredFieldsChanged);
    _grossPremiumController.removeListener(_onRequiredFieldsChanged);
    _titleController.dispose();
    _contractNumberController.dispose();
    _grossPremiumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final contractData = <String, dynamic>{
        'Title': _titleController.text.trim(),
        'ContractNumber': _nullIfBlank(_contractNumberController.text),
        'Type': _selectedType!.label,
        'StartDate': _toIsoDate(_startDate),
        'EndDate': _toIsoDate(_endDate),
        'GrossPremium': _parseNumber(_grossPremiumController.text),
        'PremiumFrequency': _selectedFrequency!.value,
        'Source': 'FILIP',
        'AdviserVisibility': true,
        'Term': _calculateTermYear(_startDate, _endDate),
        'PartnerId': _selectedPartner?.itemId,
        'PartnerName': _selectedPartner?.name,
        'PartnerItemId': _selectedPartner?.itemId,
        'ProductPartnerDescription': null,
        'Language': Localizations.localeOf(context).languageCode,
        'Tags': const <String>['Is-A-Insure', 'Is-A-Life-Insure'],
        'Status': _selectedStatus?.value,
        'DueDate': _toIsoDate(_dueDate),
        'Notes': _nullIfBlank(_notesController.text),
      };

      if (widget.initialData?.isEdit == true) {
        contractData['ItemId'] = widget.initialData?.contractId;
        await widget.repository.updateContract(
          contractEntityName: 'Insure',
          contractData: contractData,
        );
      } else {
        await widget.repository.createContract(
          contractEntityName: 'Insure',
          contractData: contractData,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showCreateFailedMessage(context);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ContractsAddFormSheet(
      title: widget.title,
      onSubmit: _submit,
      submitLabel: widget.submitLabel,
      isSubmitting: _isSubmitting,
      submitEnabled: _canSubmitRequiredFields && !_isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.type'),
              required: true,
              hint: l10n.tr('tns.type'),
              items: widget.types,
              value: _selectedType,
              itemLabel: (item) => _localizedContractTypeLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) => _requiredSelectionValidator(value, l10n),
              enabled: !_isApiDisabledField(widget.initialData, 'Type'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractTitle'),
              required: true,
              controller: _titleController,
              validator: (value) =>
                  _textValidator(value, l10n, required: true, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'Title'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractNumber'),
              controller: _contractNumberController,
              validator: (value) => _textValidator(value, l10n, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'ContractNumber'),
            ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.pensionFrequency'),
              required: true,
              hint: l10n.tr('tns.pensionFrequency'),
              items: _retirementFrequencyOptions,
              value: _selectedFrequency,
              itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedFrequency = value),
              validator: (value) => _requiredSelectionValidator(value, l10n),
              enabled: !_isApiDisabledField(widget.initialData, 'PremiumFrequency'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.grossPremium'),
              required: true,
              controller: _grossPremiumController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) => _numberValidator(
                value,
                l10n,
                required: true,
                min: 10,
                max: 999999,
              ),
              enabled: !_isApiDisabledField(widget.initialData, 'GrossPremium'),
            ),
            ContractsDropdownField<ContractsPartnerOption>(
              label: l10n.tr('tns.partner'),
              hint: l10n.tr('tns.selectPartner'),
              items: widget.partners,
              value: _selectedPartner,
              itemLabel: (item) => item.name,
              onChanged: (value) => setState(() => _selectedPartner = value),
              enabled: !_isApiDisabledField(widget.initialData, 'PartnerName'),
            ),
            ContractsDateField(
              label: l10n.tr('tns.startDate'),
              value: _startDate,
              enabled: !_isApiDisabledField(widget.initialData, 'StartDate'),
              onTap: () async {
                final value = await _pickDate(context, _startDate);
                if (value != null) setState(() => _startDate = value);
              },
            ),
            ContractsDateField(
              label: l10n.tr('tns.endDate'),
              value: _endDate,
              enabled: !_isApiDisabledField(widget.initialData, 'EndDate'),
              onTap: () async {
                final value = await _pickDate(context, _endDate);
                if (value != null) setState(() => _endDate = value);
              },
            ),
            ContractsDateField(
              label: l10n.tr('tns.dueDate'),
              value: _dueDate,
              enabled: !_isApiDisabledField(widget.initialData, 'DueDate'),
              onTap: () async {
                final value = await _pickDate(context, _dueDate);
                if (value != null) setState(() => _dueDate = value);
              },
            ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.status'),
              hint: l10n.tr('tns.status'),
              items: _retirementStatusOptions(l10n),
              value: _selectedStatus,
              itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedStatus = value),
              enabled: !_isApiDisabledField(widget.initialData, 'Status'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.notes'),
              controller: _notesController,
              maxLines: 4,
              validator: (value) =>
                  _textValidator(value, l10n, maxLength: 300),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanContractFormModal extends StatefulWidget {
  const _LoanContractFormModal({
    required this.repository,
    required this.title,
    required this.submitLabel,
    required this.types,
    required this.partners,
    this.initialData,
  });

  final ContractsRepository repository;
  final String title;
  final String submitLabel;
  final List<ContractsLookupOption> types;
  final List<ContractsPartnerOption> partners;
  final ContractsAddInitialData? initialData;

  @override
  State<_LoanContractFormModal> createState() => _LoanContractFormModalState();
}

class _LoanContractFormModalState extends State<_LoanContractFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _contractNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _fixedInterestRateController = TextEditingController();
  final _fixedInterestDurationController = TextEditingController();
  final _bankSurchargeController = TextEditingController();
  final _tradeInValueController = TextEditingController();
  final _remainingAmountController = TextEditingController();
  final _notesController = TextEditingController();

  ContractsLookupOption? _selectedType;
  ContractsPartnerOption? _selectedPartner;
  ContractsLookupOption? _selectedInterestType;
  ContractsLookupOption? _selectedReferenceRate;
  DateTime? _startOfRepayment;
  DateTime? _remainingDebtDate;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  bool get _canSubmitRequiredFields {
    return _selectedType != null && _tradeInValueController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _purposeController.text = initial.title ?? '';
      _contractNumberController.text = initial.contractNumber ?? '';
      _amountController.text = initial.loanAmount ?? '';
      _tradeInValueController.text = initial.tradeInValue ?? '';
      _notesController.text = initial.notes ?? '';
      _startDate = initial.startDate;
      _endDate = initial.endDate;
      _startOfRepayment = initial.startOfRepayment;
      _remainingDebtDate = initial.remainingDebtDate;
      _remainingAmountController.text = initial.remainingAmount ?? '';
      _fixedInterestRateController.text = initial.fixedInterestRate ?? '';
      _fixedInterestDurationController.text = initial.fixedInterestRateDuration ?? '';
      _bankSurchargeController.text = initial.bankSurcharge ?? '';
      _selectedType = _findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedInterestType = _findLookupByAny(
        _loanInterestTypeOptions,
        initial.interestTypeValueOrLabel,
      );
      _selectedReferenceRate = _findLookupByAny(
        _loanReferenceRateOptions,
        initial.referenceRateValueOrLabel,
      );
      _selectedPartner = _findPartner(widget.partners, initial.partnerName);
    }
    _tradeInValueController.addListener(_onRequiredFieldsChanged);
  }

  void _onRequiredFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tradeInValueController.removeListener(_onRequiredFieldsChanged);
    _purposeController.dispose();
    _contractNumberController.dispose();
    _amountController.dispose();
    _fixedInterestRateController.dispose();
    _fixedInterestDurationController.dispose();
    _bankSurchargeController.dispose();
    _tradeInValueController.dispose();
    _remainingAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _showsRemainingAmount =>
      _selectedType != null &&
      const <String>{
        'AND',
        'BSD',
        'TFD',
        'LEA',
        'SVF',
      }.contains(_selectedType!.value);

  bool get _showsRemainingDebtDate =>
      _selectedType != null &&
      const <String>{'AND', 'BSD', 'TFD'}.contains(_selectedType!.value);

  bool get _showsFixedInterestFields =>
      _selectedInterestType?.value.toLowerCase() == 'fixed';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = _parseNumber(_amountController.text);
      final contractData = <String, dynamic>{
        'Title': _nullIfBlank(_purposeController.text),
        'ContractNumber': _nullIfBlank(_contractNumberController.text),
        'Amount': amount,
        'Type': _selectedType!.value,
        'InterestRate': null,
        'StartDate': _toIsoDate(_startDate),
        'EndDate': _toIsoDate(_endDate),
        'StartOfRepayment': _toIsoDate(_startOfRepayment),
        'DateOfReaminingDept': _showsRemainingDebtDate
            ? _toIsoDate(_remainingDebtDate)
            : null,
        'AdviserVisibility': true,
        'PartnerItemId': _selectedPartner?.itemId,
        'RemainingAmount': _showsRemainingAmount
            ? _parseNumber(_remainingAmountController.text)
            : null,
        'PartnerName': _selectedPartner?.name,
        'InterestOnlyPeriod': null,
        'ResidualValue': null,
        'ValueOfTradeIn': _parseNumber(_tradeInValueController.text),
        'PayableAmount': amount,
        'InterestAmount': null,
        'PaidTillNow': null,
        'AmountPayableAfterIOPeriod': null,
        'AmountLeft': amount,
        'Collateral': null,
        'ProductPartnerDescription': null,
        'Term': _calculateTermMonth(_startDate, _endDate),
        'Language': Localizations.localeOf(context).languageCode,
        'Tags': const <String>['Is-A-Loan'],
        'TypeOfInterest': _selectedInterestType?.value,
        'FixedInterestRate': _showsFixedInterestFields
            ? _parseNumber(_fixedInterestRateController.text)
            : null,
        'FixedInterestRateDuration': _showsFixedInterestFields
            ? _parseNumber(_fixedInterestDurationController.text)?.toInt()
            : null,
        'ReferenceInterestRate': _selectedReferenceRate?.value,
        'BankSurcharge': _parseNumber(_bankSurchargeController.text),
        'Notes': _nullIfBlank(_notesController.text),
      };

      if (widget.initialData?.isEdit == true) {
        contractData['ItemId'] = widget.initialData?.contractId;
        await widget.repository.updateContract(
          contractEntityName: 'Loan',
          contractData: contractData,
        );
      } else {
        await widget.repository.createContract(
          contractEntityName: 'Loan',
          contractData: contractData,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showCreateFailedMessage(context);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.initialData?.isEdit == true;

    return ContractsAddFormSheet(
      title: widget.title,
      onSubmit: _submit,
      submitLabel: widget.submitLabel,
      isSubmitting: _isSubmitting,
      submitEnabled: _canSubmitRequiredFields && !_isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.loanType'),
              required: true,
              hint: l10n.tr('tns.loanType'),
              items: widget.types,
              value: _selectedType,
              itemLabel: (item) => _localizedContractTypeLabel(item, l10n),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  if (!_showsRemainingAmount) {
                    _remainingAmountController.clear();
                  }
                  if (!_showsRemainingDebtDate) {
                    _remainingDebtDate = null;
                  }
                });
              },
              validator: (value) => _requiredSelectionValidator(value, l10n),
              enabled: !_isApiDisabledField(widget.initialData, 'Type'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.purposeOfUse'),
              controller: _purposeController,
              validator: (value) => _textValidator(value, l10n, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'PurposeOfUse'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractNumber'),
              controller: _contractNumberController,
              validator: (value) => _textValidator(value, l10n, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'ContractNumber'),
            ),
            ContractsDropdownField<ContractsPartnerOption>(
              label: l10n.tr('tns.bankingInstitute'),
              hint: l10n.tr('tns.selectPartner'),
              items: widget.partners,
              value: _selectedPartner,
              itemLabel: (item) => item.name,
              onChanged: (value) => setState(() => _selectedPartner = value),
              enabled: !_isApiDisabledField(widget.initialData, 'PartnerName'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.loanAmount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) =>
                  _numberValidator(value, l10n, min: 100, max: 9999999999),
              enabled: !_isApiDisabledField(widget.initialData, 'Amount'),
            ),
            ContractsDateField(
              label: l10n.tr('tns.startOfRepayment'),
              value: _startOfRepayment,
              enabled: !_isApiDisabledField(widget.initialData, 'StartOfRepayment'),
              onTap: () async {
                final value = await _pickDate(context, _startOfRepayment);
                if (value != null) setState(() => _startOfRepayment = value);
              },
            ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.typeOfInterest'),
              hint: l10n.tr('tns.typeOfInterest'),
              items: _loanInterestTypeOptions,
              value: _selectedInterestType,
              itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
              onChanged: (value) {
                setState(() {
                  _selectedInterestType = value;
                  if (!_showsFixedInterestFields) {
                    _fixedInterestRateController.clear();
                    _fixedInterestDurationController.clear();
                  }
                });
              },
            ),
            if (_showsFixedInterestFields)
              ContractsTextField(
                label: l10n.tr('tns.fixedInterestRate'),
                controller: _fixedInterestRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: '%',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0.1, max: 25),
              ),
            if (_showsFixedInterestFields)
              ContractsTextField(
                label: l10n.tr('tns.fixedInterestRateDuration'),
                controller: _fixedInterestDurationController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                validator: (value) =>
                    _numberValidator(value, l10n, min: 1, max: 50),
              ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.referenceInterestRate'),
              hint: l10n.tr('tns.referenceInterestRate'),
              items: _loanReferenceRateOptions,
              value: _selectedReferenceRate,
              itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
              onChanged: (value) =>
                  setState(() => _selectedReferenceRate = value),
            ),
            ContractsTextField(
              label: l10n.tr('tns.bankSurcharge'),
              controller: _bankSurchargeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: '%',
              validator: (value) =>
                  _numberValidator(value, l10n, min: 0.1, max: 25),
            ),
            ContractsTextField(
              label: l10n.tr('tns.tradeInValue'),
              required: true,
              controller: _tradeInValueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) => _numberValidator(
                value,
                l10n,
                required: true,
                min: 0,
                max: 9999999999,
              ),
              enabled: !_isApiDisabledField(widget.initialData, 'ValueOfTradeIn'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.remainingLoan'),
              controller: _remainingAmountController,
              enabled: _showsRemainingAmount && !_isApiDisabledField(widget.initialData, 'RemainingAmount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) => !_showsRemainingAmount
                  ? null
                  : _numberValidator(
                      value,
                      l10n,
                      required: _remainingDebtDate != null,
                      min: 0,
                      max: 9999999999,
                    ),
            ),
            ContractsDateField(
              label: l10n.tr('tns.dateOfRemainingDebt'),
              required: !isEdit && _remainingAmountController.text.trim().isNotEmpty,
              value: _remainingDebtDate,
              enabled: _showsRemainingDebtDate && !_isApiDisabledField(widget.initialData, 'DateOfReaminingDept'),
              onTap: () async {
                final value = await _pickDate(context, _remainingDebtDate);
                if (value != null) setState(() => _remainingDebtDate = value);
              },
              validator: (_) =>
                  !_showsRemainingDebtDate ||
                      _remainingAmountController.text.trim().isEmpty
                  ? null
                  : _remainingDebtDate == null
                  ? l10n.tr('tns.fieldRequired')
                  : null,
            ),
            ContractsDateField(
              label: l10n.tr('tns.loanConclusionDate'),
              value: _startDate,
              enabled: !_isApiDisabledField(widget.initialData, 'StartDate'),
              onTap: () async {
                final value = await _pickDate(context, _startDate);
                if (value != null) setState(() => _startDate = value);
              },
            ),
            ContractsDateField(
              label: l10n.tr('tns.endDate'),
              value: _endDate,
              enabled: !_isApiDisabledField(widget.initialData, 'EndDate'),
              onTap: () async {
                final value = await _pickDate(context, _endDate);
                if (value != null) setState(() => _endDate = value);
              },
            ),
            ContractsTextField(
              label: l10n.tr('tns.notes'),
              controller: _notesController,
              maxLines: 4,
              validator: (value) =>
                  _textValidator(value, l10n, maxLength: 300),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentContractFormModal extends StatefulWidget {
  const _InvestmentContractFormModal({
    required this.repository,
    required this.title,
    required this.submitLabel,
    required this.types,
    required this.partners,
    this.initialData,
  });

  final ContractsRepository repository;
  final String title;
  final String submitLabel;
  final List<ContractsLookupOption> types;
  final List<ContractsPartnerOption> partners;
  final ContractsAddInitialData? initialData;

  @override
  State<_InvestmentContractFormModal> createState() =>
      _InvestmentContractFormModalState();
}

class _InvestmentContractFormModalState
    extends State<_InvestmentContractFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _investmentBookValueController = TextEditingController();
  final _investmentCurrentValueController = TextEditingController();
  final _lumpSumInvestmentController = TextEditingController();
  final _riskController = TextEditingController();
  final _isinController = TextEditingController();
  final _numberOfSharesController = TextEditingController();
  final _currentShareValueController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _couponRateController = TextEditingController();
  final _issuerController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bicController = TextEditingController();
  final _bondPriceController = TextEditingController();
  final _notesController = TextEditingController();

  ContractsLookupOption? _selectedType;
  ContractsPartnerOption? _selectedPartner;
  ContractsLookupOption? _selectedPaymentFrequency;
  ContractsLookupOption? _selectedCouponType;
  ContractsLookupOption? _selectedCurrency;
  ContractsLookupOption? _selectedCouponPeriod;
  bool? _isTargetSumSavingsPlan;
  bool? _isPremiumBenefit;
  DateTime? _bookValueDate;
  DateTime? _bondPriceDate;
  DateTime? _currentValueDate;
  DateTime? _investmentStartDate;
  DateTime? _investmentEndDate;
  bool _isSubmitting = false;

  bool get _canSubmitRequiredFields {
    return _selectedType != null && _titleController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _titleController.text = initial.title ?? '';
      _accountNumberController.text = initial.accountNumber ?? '';
      _investmentBookValueController.text = initial.bookValue ?? '';
      _investmentCurrentValueController.text = initial.currentValue ?? '';
      _lumpSumInvestmentController.text = initial.lumpSumInvestment ?? '';
      _notesController.text = initial.notes ?? '';
      _investmentStartDate = initial.startDate;
      _investmentEndDate = initial.endDate;
      _bookValueDate = initial.bookValueDate;
      _currentValueDate = initial.currentValueDate;
      _riskController.text = initial.risk ?? '';
      _isinController.text = initial.isin ?? '';
      _numberOfSharesController.text = initial.numberOfShares ?? '';
      _currentShareValueController.text = initial.currentShareValue ?? '';
      _interestRateController.text = initial.interestRate ?? '';
      _couponRateController.text = initial.couponRate ?? '';
      _issuerController.text = initial.issuer ?? '';
      _ibanController.text = initial.iban ?? '';
      _bicController.text = initial.bic ?? '';
      _bondPriceController.text = initial.bondPrice ?? '';
      _bondPriceDate = initial.bondPriceDate;
      _selectedType = _findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedPaymentFrequency = _findLookupByAny(
        _investmentPaymentFrequencyOptions,
        initial.paymentFrequencyValueOrLabel,
      );
      _selectedCouponType = _findLookupByAny(
        _couponTypeOptions,
        initial.couponTypeValueOrLabel,
      );
      _selectedCouponPeriod = _findLookupByAny(
        _couponPeriodOptions,
        initial.couponPeriodValueOrLabel,
      );
      _selectedCurrency = _findLookupByAny(
        _currencyOptions,
        initial.currencyValueOrLabel,
      );
      _isTargetSumSavingsPlan = initial.isTargetSumSavingsPlan;
      _isPremiumBenefit = initial.isPremiumBenefit;
      _selectedPartner = _findPartner(widget.partners, initial.partnerName);
      _resetForTypeChange();
    }
    _titleController.addListener(_onRequiredFieldsChanged);
  }

  void _onRequiredFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onRequiredFieldsChanged);
    _titleController.dispose();
    _accountNumberController.dispose();
    _investmentBookValueController.dispose();
    _investmentCurrentValueController.dispose();
    _lumpSumInvestmentController.dispose();
    _riskController.dispose();
    _isinController.dispose();
    _numberOfSharesController.dispose();
    _currentShareValueController.dispose();
    _interestRateController.dispose();
    _couponRateController.dispose();
    _issuerController.dispose();
    _ibanController.dispose();
    _bicController.dispose();
    _bondPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _selectedTypeCode => _selectedType?.value ?? '';

  bool _typeIn(Set<String> values) => values.contains(_selectedTypeCode);

  bool get _showAccountNumber =>
      !_typeIn(const <String>{'BUILDER_OWNER_MODEL'});
  bool get _showDateRange =>
      !_typeIn(const <String>{'SAVINGS_BOOK', 'SAVINGS_ACCOUNT_OR_CASH'});
  bool get _showBookValueDate =>
      _typeIn(_investmentBookValueDateTypes) &&
      !_typeIn(_investmentNoBookValueDateTypes);
  bool get _showPaymentFrequency =>
      !_typeIn(const <String>{'FIXED_DEPOSIT'}) ||
      _typeIn(const <String>{'BUILDER_OWNER_MODEL', 'SAVINGS_BOOK'});
  bool get _showTargetSumSavingsPlan => _typeIn(_investmentTargetSumTypes);
  bool get _showRisk => _typeIn(_investmentRiskTypes);
  bool get _showIsin => _typeIn(_investmentIsinTypes);
  bool get _showCurrentValue => _typeIn(_investmentCurrentValueTypes);
  bool get _showCurrentValueDate => _typeIn(_investmentCurrentValueDateTypes);
  bool get _showCurrentShareValue => _typeIn(_investmentCurrentShareValueTypes);
  bool get _showNumberOfShares => _typeIn(_investmentNumberOfSharesTypes);
  bool get _showCouponRate => _typeIn(const <String>{'BONDS'});
  bool get _showCouponPeriod => _typeIn(const <String>{'BONDS'});
  bool get _showCouponType => _typeIn(const <String>{'BONDS'});
  bool get _showIssuer => _typeIn(const <String>{'BONDS'});
  bool get _showBondPrice => _typeIn(const <String>{'BONDS'});
  bool get _showBondPriceDate => _typeIn(const <String>{'BONDS'});
  bool get _showCurrency => _typeIn(const <String>{'BONDS'});
  bool get _showIban => _typeIn(const <String>{'SAVINGS_ACCOUNT_OR_CASH'});
  bool get _showBic => _typeIn(const <String>{'SAVINGS_ACCOUNT_OR_CASH'});
  bool get _showPremiumBenefit => _typeIn(const <String>{'BUILDING_SAVINGS'});
  bool get _showInterestRate => _typeIn(const <String>{
    'SAVINGS_BOOK',
    'SAVINGS_ACCOUNT_OR_CASH',
    'FIXED_DEPOSIT',
  });

  void _resetForTypeChange() {
    if (!_showAccountNumber) {
      _accountNumberController.clear();
    }
    if (!_showDateRange) {
      _investmentStartDate = null;
      _investmentEndDate = null;
    }
    if (!_showBookValueDate) {
      _bookValueDate = null;
    }
    if (!_showTargetSumSavingsPlan) {
      _isTargetSumSavingsPlan = null;
    }
    if (!_showRisk) {
      _riskController.clear();
    }
    if (!_showIsin) {
      _isinController.clear();
    }
    if (!_showCurrentValueDate) {
      _currentValueDate = null;
    }
    if (!_showCurrentShareValue) {
      _currentShareValueController.clear();
    }
    if (!_showNumberOfShares) {
      _numberOfSharesController.clear();
    }
    if (!_showCouponRate) {
      _couponRateController.clear();
    }
    if (!_showCouponPeriod) {
      _selectedCouponPeriod = null;
    }
    if (!_showCouponType) {
      _selectedCouponType = null;
    }
    if (!_showIssuer) {
      _issuerController.clear();
    }
    if (!_showBondPrice) {
      _bondPriceController.clear();
      _bondPriceDate = null;
    }
    if (!_showCurrency) {
      _selectedCurrency = null;
    }
    if (!_showIban) {
      _ibanController.clear();
    }
    if (!_showBic) {
      _bicController.clear();
    }
    if (!_showPremiumBenefit) {
      _isPremiumBenefit = null;
    }
    if (!_showInterestRate) {
      _interestRateController.clear();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final contractData = <String, dynamic>{
        'Title': _titleController.text.trim(),
        'InvestmentBookValue': _parseNumber(
          _investmentBookValueController.text,
        ),
        'InvestmentCurrentValue': _parseNumber(
          _investmentCurrentValueController.text,
        ),
        'AccountNumber': _showAccountNumber
            ? _nullIfBlank(_accountNumberController.text)
            : null,
        'PartnerItemId': _selectedPartner?.itemId,
        'PartnerName': _selectedPartner?.name,
        'ProductPartnerDescription': null,
        'InvestmentType': _selectedType!.label,
        'Notes': _nullIfBlank(_notesController.text),
        'BookValueDate': _showBookValueDate
            ? _toIsoDate(_bookValueDate)
            : null,
        'BondPriceDate': _showBondPriceDate
            ? _toIsoDate(_bondPriceDate)
            : null,
        'CurrentValueDate': _showCurrentValueDate
            ? _toIsoDate(_currentValueDate)
            : null,
        'InvestmentStartDate': _showDateRange
            ? _toIsoDate(_investmentStartDate)
            : null,
        'InvestmentEndDate': _showDateRange
            ? _toIsoDate(_investmentEndDate)
            : null,
        'PaymentFrequency': _selectedPaymentFrequency?.value,
        'IsTargetSumSavingsPlan': _showTargetSumSavingsPlan
            ? _isTargetSumSavingsPlan
            : null,
        'LumpSumInvestment': _parseNumber(_lumpSumInvestmentController.text),
        'Risk': _showRisk ? _parseNumber(_riskController.text) : null,
        'ISIN': _showIsin ? _nullIfBlank(_isinController.text) : null,
        'NumberofShares': _showNumberOfShares
            ? _parseNumber(_numberOfSharesController.text)
            : null,
        'CurrentShareValue': _showCurrentShareValue
            ? _parseNumber(_currentShareValueController.text)
            : null,
        'InterestRate': _showInterestRate
            ? _parseNumber(_interestRateController.text)
            : null,
        'CouponType': _showCouponType ? _selectedCouponType?.value : null,
        'CouponRate': _showCouponRate
            ? _parseNumber(_couponRateController.text)
            : null,
        'IBAN': _showIban ? _nullIfBlank(_ibanController.text) : null,
        'BIC': _showBic ? _nullIfBlank(_bicController.text) : null,
        'Currency': _showCurrency ? _selectedCurrency?.value : null,
        'Issuer': _showIssuer ? _nullIfBlank(_issuerController.text) : null,
        'IsPremiumBenefit': _showPremiumBenefit ? _isPremiumBenefit : null,
        'BondPrice': _showBondPrice
            ? _parseNumber(_bondPriceController.text)
            : null,
        'CouponPeriod': _showCouponPeriod
            ? _selectedCouponPeriod?.value
            : null,
        'AdviserVisibility': true,
        'Language': Localizations.localeOf(context).languageCode,
        'Tags': const <String>['Is-A-Investment'],
      };

      if (widget.initialData?.isEdit == true) {
        contractData['ItemId'] = widget.initialData?.contractId;
        await widget.repository.updateContract(
          contractEntityName: 'Investment',
          contractData: contractData,
        );
      } else {
        await widget.repository.createContract(
          contractEntityName: 'Investment',
          contractData: contractData,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showCreateFailedMessage(context);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ContractsAddFormSheet(
      title: widget.title,
      onSubmit: _submit,
      submitLabel: widget.submitLabel,
      isSubmitting: _isSubmitting,
      submitEnabled: _canSubmitRequiredFields && !_isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.type'),
              required: true,
              hint: l10n.tr('tns.type'),
              items: widget.types,
              value: _selectedType,
              itemLabel: (item) => _localizedContractTypeLabel(item, l10n),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _resetForTypeChange();
                });
              },
              validator: (value) => _requiredSelectionValidator(value, l10n),
              enabled: !_isApiDisabledField(widget.initialData, 'InvestmentType'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractTitle'),
              required: true,
              controller: _titleController,
              validator: (value) =>
                  _textValidator(value, l10n, required: true, maxLength: 50),
              enabled: !_isApiDisabledField(widget.initialData, 'Title'),
            ),
            ContractsDropdownField<ContractsPartnerOption>(
              label: l10n.tr('tns.partner'),
              hint: l10n.tr('tns.selectPartner'),
              items: widget.partners,
              value: _selectedPartner,
              itemLabel: (item) => item.name,
              onChanged: (value) => setState(() => _selectedPartner = value),
              enabled: !_isApiDisabledField(widget.initialData, 'PartnerName'),
            ),
            if (_showAccountNumber)
              ContractsTextField(
                label: _accountNumberLabel(l10n, _selectedTypeCode),
                controller: _accountNumberController,
                validator: (value) =>
                    _textValidator(value, l10n, maxLength: 50),
                enabled: !_isApiDisabledField(widget.initialData, 'AccountNumber'),
              ),
            if (_showDateRange)
              ContractsDateField(
                label: _startDateLabel(l10n, _selectedTypeCode),
                value: _investmentStartDate,
                enabled: !_isApiDisabledField(widget.initialData, 'InvestmentStartDate'),
                onTap: () async {
                  final value = await _pickDate(context, _investmentStartDate);
                  if (value != null) {
                    setState(() => _investmentStartDate = value);
                  }
                },
              ),
            if (_showDateRange)
              ContractsDateField(
                label: _endDateLabel(l10n, _selectedTypeCode),
                value: _investmentEndDate,
                enabled: !_isApiDisabledField(widget.initialData, 'InvestmentEndDate'),
                onTap: () async {
                  final value = await _pickDate(context, _investmentEndDate);
                  if (value != null) {
                    setState(() => _investmentEndDate = value);
                  }
                },
              ),
            const SizedBox(height: 6),
            ContractsFormSectionTitle(l10n.tr('tns.contractDetails')),
            ContractsTextField(
              label: _bookValueLabel(l10n, _selectedTypeCode),
              controller: _investmentBookValueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) =>
                  _numberValidator(value, l10n, min: 0, max: 99999999),
              enabled: !_isApiDisabledField(widget.initialData, 'InvestmentBookValue'),
            ),
            if (_showBookValueDate)
              ContractsDateField(
                label: _bookValueDateLabel(l10n, _selectedTypeCode),
                value: _bookValueDate,
                onTap: () async {
                  final value = await _pickDate(context, _bookValueDate);
                  if (value != null) setState(() => _bookValueDate = value);
                },
              ),
            if (_showPaymentFrequency)
              ContractsDropdownField<ContractsLookupOption>(
                label: _paymentMethodLabel(l10n, _selectedTypeCode),
                hint: _paymentMethodLabel(l10n, _selectedTypeCode),
                items: _investmentPaymentFrequencyOptions,
                value: _selectedPaymentFrequency,
                itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
                onChanged: (value) =>
                    setState(() => _selectedPaymentFrequency = value),
              ),
            if (_showTargetSumSavingsPlan)
              ContractsDropdownField<bool>(
                label: l10n.tr('tns.targetSumSavingsPlan'),
                hint: l10n.tr('tns.targetSumSavingsPlan'),
                items: const <bool>[true, false],
                value: _isTargetSumSavingsPlan,
                itemLabel: (item) =>
                    item ? l10n.tr('common.yes') : l10n.tr('common.no'),
                onChanged: (value) =>
                    setState(() => _isTargetSumSavingsPlan = value),
              ),
            ContractsTextField(
              label: l10n.tr('tns.lumpSumInvestment'),
              controller: _lumpSumInvestmentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'EUR',
              validator: (value) =>
                  _numberValidator(value, l10n, min: 0, max: 99999999),
            ),
            if (_showRisk)
              ContractsTextField(
                label: l10n.tr('tns.risk'),
                controller: _riskController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: '%',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 100),
              ),
            if (_showIsin)
              ContractsTextField(
                label: l10n.tr('tns.isin'),
                controller: _isinController,
                validator: (value) =>
                    _textValidator(value, l10n, maxLength: 50),
                enabled: !_isApiDisabledField(widget.initialData, 'ISIN'),
              ),
            if (_showCurrentValue)
              ContractsTextField(
                label: l10n.tr('tns.currentValue'),
                controller: _investmentCurrentValueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: 'EUR',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 99999999),
                enabled: !_isApiDisabledField(widget.initialData, 'InvestmentCurrentValue'),
              ),
            if (_showCurrentShareValue)
              ContractsTextField(
                label: l10n.tr('tns.currentShareValue'),
                controller: _currentShareValueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: 'EUR',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            if (_showCurrentValueDate)
              ContractsDateField(
                label: l10n.tr('tns.currentValueDate'),
                value: _currentValueDate,
                onTap: () async {
                  final value = await _pickDate(context, _currentValueDate);
                  if (value != null) setState(() => _currentValueDate = value);
                },
              ),
            if (_showNumberOfShares)
              ContractsTextField(
                label: l10n.tr('tns.numberOfShares'),
                controller: _numberOfSharesController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 99999999),
                enabled: !_isApiDisabledField(widget.initialData, 'NumberofShares'),
              ),
            if (_showCouponRate)
              ContractsTextField(
                label: l10n.tr('tns.couponRate'),
                controller: _couponRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: '%',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            if (_showCouponPeriod)
              ContractsDropdownField<ContractsLookupOption>(
                label: l10n.tr('tns.couponPeriod'),
                hint: l10n.tr('tns.couponPeriod'),
                items: _couponPeriodOptions,
                value: _selectedCouponPeriod,
                itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
                onChanged: (value) =>
                    setState(() => _selectedCouponPeriod = value),
              ),
            if (_showCouponType)
              ContractsDropdownField<ContractsLookupOption>(
                label: l10n.tr('tns.couponType'),
                hint: l10n.tr('tns.couponType'),
                items: _couponTypeOptions,
                value: _selectedCouponType,
                itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
                onChanged: (value) =>
                    setState(() => _selectedCouponType = value),
              ),
            if (_showIssuer)
              ContractsTextField(
                label: l10n.tr('tns.issuer'),
                controller: _issuerController,
                validator: (value) =>
                    _textValidator(value, l10n, maxLength: 50),
              ),
            if (_showBondPrice)
              ContractsTextField(
                label: l10n.tr('tns.bondPrice'),
                controller: _bondPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: 'EUR',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            if (_showBondPriceDate)
              ContractsDateField(
                label: l10n.tr('tns.bondPriceDate'),
                value: _bondPriceDate,
                enabled: !_isApiDisabledField(widget.initialData, 'BondPriceDate'),
                onTap: () async {
                  final value = await _pickDate(context, _bondPriceDate);
                  if (value != null) setState(() => _bondPriceDate = value);
                },
              ),
            if (_showCurrency)
              ContractsDropdownField<ContractsLookupOption>(
                label: l10n.tr('tns.currency'),
                hint: l10n.tr('tns.currency'),
                items: _currencyOptions,
                value: _selectedCurrency,
                itemLabel: (item) => _localizedStaticOptionLabel(item, l10n),
                onChanged: (value) => setState(() => _selectedCurrency = value),
              ),
            if (_showIban)
              ContractsTextField(
                label: l10n.tr('tns.iban'),
                controller: _ibanController,
                validator: (value) =>
                    _textValidator(value, l10n, maxLength: 50),
              ),
            if (_showBic)
              ContractsTextField(
                label: l10n.tr('tns.bic'),
                controller: _bicController,
                validator: (value) =>
                    _textValidator(value, l10n, maxLength: 50),
              ),
            if (_showPremiumBenefit)
              ContractsDropdownField<bool>(
                label: l10n.tr('tns.premiumBenefit'),
                hint: l10n.tr('tns.premiumBenefit'),
                items: const <bool>[true, false],
                value: _isPremiumBenefit,
                itemLabel: (item) =>
                    item ? l10n.tr('common.yes') : l10n.tr('common.no'),
                onChanged: (value) => setState(() => _isPremiumBenefit = value),
              ),
            if (_showInterestRate)
              ContractsTextField(
                label: l10n.tr('tns.interestRate'),
                controller: _interestRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffixText: '%',
                validator: (value) =>
                    _numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            ContractsTextField(
              label: l10n.tr('tns.notes'),
              controller: _notesController,
              maxLines: 4,
              validator: (value) =>
                  _textValidator(value, l10n, maxLength: 300),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractsAddBootstrapData {
  const _ContractsAddBootstrapData({
    required this.types,
    required this.partners,
    this.fullContractDetails,
  });

  final List<ContractsLookupOption> types;
  final List<ContractsPartnerOption> partners;
  final Map<String, dynamic>? fullContractDetails;
}

String _lookupEntityName(ContractsAddKind kind) {
  switch (kind) {
    case ContractsAddKind.insurance:
      return 'Insure';
    case ContractsAddKind.retirement:
      return 'Retirement';
    case ContractsAddKind.loan:
      return 'Loan';
    case ContractsAddKind.investment:
      return 'Investment';
  }
}

String _apiEntityName(ContractsAddKind kind) {
  switch (kind) {
    case ContractsAddKind.insurance:
      return 'Insure';
    case ContractsAddKind.retirement:
      return 'Insure';
    case ContractsAddKind.loan:
      return 'Loan';
    case ContractsAddKind.investment:
      return 'Investment';
  }
}

String _titleKey(ContractsAddKind kind) {
  switch (kind) {
    case ContractsAddKind.insurance:
      return 'tns.addInsuranceContract';
    case ContractsAddKind.retirement:
      return 'tns.addRetirementContract';
    case ContractsAddKind.loan:
      return 'tns.addLoanContract';
    case ContractsAddKind.investment:
      return 'tns.addInvestmentContract';
  }
}

String _editTitleKey(ContractsAddKind kind) {
  switch (kind) {
    case ContractsAddKind.insurance:
      return 'tns.editInsuranceContract';
    case ContractsAddKind.retirement:
      return 'tns.editRetirementContract';
    case ContractsAddKind.loan:
      return 'tns.editLoanContract';
    case ContractsAddKind.investment:
      return 'tns.editInvestmentContract';
  }
}

class ContractsAddInitialData {
  const ContractsAddInitialData({
    this.isEdit = false,
    this.contractId,
    this.typeValueOrLabel,
    this.title,
    this.contractNumber,
    this.partnerName,
    this.premiumFrequencyValueOrLabel,
    this.paymentFrequencyValueOrLabel,
    this.grossPremium,
    this.insuranceAmount,
    this.loanAmount,
    this.tradeInValue,
    this.accountNumber,
    this.bookValue,
    this.currentValue,
    this.lumpSumInvestment,
    this.notes,
    this.startDate,
    this.endDate,
    this.dueDate,
    this.bookValueDate,
    this.currentValueDate,
    this.status,
    this.isin,
    this.currentShareValue,
    this.numberOfShares,
    this.interestRate,
    this.couponRate,
    this.couponTypeValueOrLabel,
    this.couponPeriodValueOrLabel,
    this.currencyValueOrLabel,
    this.issuer,
    this.bondPrice,
    this.bondPriceDate,
    this.risk,
    this.isTargetSumSavingsPlan,
    this.isPremiumBenefit,
    this.iban,
    this.bic,
    this.interestTypeValueOrLabel,
    this.fixedInterestRate,
    this.fixedInterestRateDuration,
    this.referenceRateValueOrLabel,
    this.bankSurcharge,
    this.remainingAmount,
    this.remainingDebtDate,
    this.startOfRepayment,
    this.syncDisabledProperties,
    this.isLifeTime,
  });

  final bool isEdit;
  final List<String>? syncDisabledProperties;
  final bool? isLifeTime;
  final String? contractId;
  final String? typeValueOrLabel;
  final String? title;
  final String? contractNumber;
  final String? partnerName;
  final String? premiumFrequencyValueOrLabel;
  final String? paymentFrequencyValueOrLabel;
  final String? grossPremium;
  final String? insuranceAmount;
  final String? loanAmount;
  final String? tradeInValue;
  final String? accountNumber;
  final String? bookValue;
  final String? currentValue;
  final String? lumpSumInvestment;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? dueDate;
  final DateTime? bookValueDate;
  final DateTime? currentValueDate;
  final String? status;
  final String? isin;
  final String? currentShareValue;
  final String? numberOfShares;
  final String? interestRate;
  final String? couponRate;
  final String? couponTypeValueOrLabel;
  final String? couponPeriodValueOrLabel;
  final String? currencyValueOrLabel;
  final String? issuer;
  final String? bondPrice;
  final DateTime? bondPriceDate;
  final String? risk;
  final bool? isTargetSumSavingsPlan;
  final bool? isPremiumBenefit;
  final String? iban;
  final String? bic;
  final String? interestTypeValueOrLabel;
  final String? fixedInterestRate;
  final String? fixedInterestRateDuration;
  final String? referenceRateValueOrLabel;
  final String? bankSurcharge;
  final String? remainingAmount;
  final DateTime? remainingDebtDate;
  final DateTime? startOfRepayment;
}

bool _isApiDisabledField(ContractsAddInitialData? initial, String field) {
  if (initial == null || !initial.isEdit) return false;
  final isDisabled = initial.syncDisabledProperties?.contains(field) ?? false;
  // ignore: avoid_print
  if (isDisabled) print('[contracts] Field "$field" is DISABLED by API');
  return isDisabled;
}

ContractsLookupOption? _findLookupByAny(
  List<ContractsLookupOption> options,
  String? valueOrLabel,
) {
  final target = valueOrLabel?.trim().toLowerCase();
  if (target == null || target.isEmpty) return null;
  for (final option in options) {
    if (option.value.trim().toLowerCase() == target ||
        option.label.trim().toLowerCase() == target) {
      return option;
    }
  }
  return null;
}

ContractsPartnerOption? _findPartner(
  List<ContractsPartnerOption> partners,
  String? partnerName,
) {
  final target = partnerName?.trim().toLowerCase();
  if (target == null || target.isEmpty) return null;
  for (final partner in partners) {
    if (partner.name.trim().toLowerCase() == target) {
      return partner;
    }
  }
  return null;
}

String? _requiredSelectionValidator(Object? value, AppLocalizations l10n) {
  return value == null ? l10n.tr('tns.fieldRequired') : null;
}

String? _textValidator(
  String? value,
  AppLocalizations l10n, {
  bool required = false,
  int? minLength,
  int? maxLength,
}) {
  final trimmed = value?.trim() ?? '';
  if (required && trimmed.isEmpty) {
    return l10n.tr('tns.fieldRequired');
  }
  if (trimmed.isEmpty) return null;
  if (minLength != null && trimmed.length < minLength) {
    return l10n.tr('tns.minimumCharacters', {'count': '$minLength'});
  }
  if (maxLength != null && trimmed.length > maxLength) {
    return l10n.tr('tns.maximumCharacters', {'count': '$maxLength'});
  }
  return null;
}

String? _numberValidator(
  String? value,
  AppLocalizations l10n, {
  bool required = false,
  double? min,
  double? max,
}) {
  final trimmed = value?.trim() ?? '';
  if (required && trimmed.isEmpty) {
    return l10n.tr('tns.fieldRequired');
  }
  if (trimmed.isEmpty) return null;

  final parsed = _parseNumber(trimmed);
  if (parsed == null) {
    return l10n.tr('tns.enterValidNumber');
  }
  if (min != null && parsed < min) {
    return l10n.tr('tns.minimumValue', {'value': _formatValidationNumber(min)});
  }
  if (max != null && parsed > max) {
    return l10n.tr('tns.maximumValue', {'value': _formatValidationNumber(max)});
  }
  return null;
}

double? _parseNumber(String? text) {
  if (text == null) return null;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;

  String normalized = trimmed.replaceAll(' ', '');
  if (normalized.contains('.') && normalized.contains(',')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '.');
  }
  return double.tryParse(normalized);
}

String? _nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _toIsoDate(DateTime? value) {
  if (value == null) return null;
  return DateTime(value.year, value.month, value.day).toIso8601String();
}

String _calculateTermYear(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return '0';
  return (endDate.year - startDate.year + 1).toString();
}

int _calculateTermMonth(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return 0;

  final dateDiff = endDate.difference(startDate).inDays;
  final startMonth = startDate.month;
  final endMonth = endDate.month;
  var months = (endMonth - startMonth).abs();
  var years = endDate.year - startDate.year;

  if (endMonth < startMonth) {
    years--;
    months = 12 - months;
  } else if (dateDiff <= 31) {
    return 1;
  }

  return years * 12 + months;
}

Future<DateTime?> _pickDate(BuildContext context, DateTime? initialDate) {
  return showContractsWheelDatePicker(context, initialDate);
}

void _showCreateFailedMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.tr('tns.contractCreateFailed'))),
  );
}

String _formatValidationNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}

String _bookValueLabel(AppLocalizations l10n, String typeName) {
  if (const <String>{'BONDS'}.contains(typeName)) {
    return l10n.tr('tns.bookValueBond');
  }

  if (const <String>{
    'BUILDER_OWNER_MODEL',
    'MONEY_MARKET_FUNDS',
    'REAL_ESTATE_FUNDS',
    'MIXED_FUNDS',
    'SAVINGS_BOOK',
    'SAVINGS_ACCOUNT_OR_CASH',
    'FIXED_DEPOSIT',
    'VALUE_PROTECTION',
    'OTHER_SPECIAL_INVESTMENTS',
    'BUILDING_SAVINGS',
  }.contains(typeName)) {
    return l10n.tr('tns.investmentAmount');
  }

  return l10n.tr('tns.bookValue');
}

String _bookValueDateLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.priceDate')
      : l10n.tr('tns.valueAtOpening');
}

String _startDateLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.purchaseDate')
      : l10n.tr('tns.startDate');
}

String _endDateLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.maturityDate')
      : l10n.tr('tns.endDate');
}

String _paymentMethodLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.paymentFrequency')
      : l10n.tr('tns.paymentMethod');
}

String _accountNumberLabel(AppLocalizations l10n, String typeName) {
  if (typeName == 'BUILDING_SAVINGS') {
    return l10n.tr('tns.contractNumber');
  }
  return l10n.tr('tns.accountNumber');
}

String _localizedStaticOptionLabel(
  ContractsLookupOption option,
  AppLocalizations l10n,
) {
  switch (option.value) {
    case 'Monthly':
      return l10n.tr('tns.monthly');
    case 'Quarterly':
      return l10n.tr('tns.quarterly');
    case 'Half Yearly':
      return l10n.tr('tns.halfYearly');
    case 'Annually':
      return l10n.tr('tns.annually');
    case 'One Time':
      return l10n.tr('tns.oneTime');
    case 'Semi Annually':
      return l10n.tr('tns.semiAnnually');
    case 'Once':
      return l10n.tr('tns.once');
    case 'other, unknown':
      return l10n.tr('tns.otherUnknown');
    case 'Variable':
      return l10n.tr('tns.variable');
    case 'Fixed':
      return l10n.tr('tns.fixed');
    case '3-Month Euribor':
      return l10n.tr('tns.euribor3m');
    case '6-Month Euribor':
      return l10n.tr('tns.euribor6m');
    case '12-Month Euribor':
      return l10n.tr('tns.euribor12m');
    case 'Prime Rate':
      return l10n.tr('tns.primeRate');
    case 'Fixed Rate':
      return l10n.tr('tns.fixedRate');
    case 'Step-Up Rate':
      return l10n.tr('tns.stepUpRate');
    case 'Variable Rate':
      return l10n.tr('tns.variableRate');
    case 'Zero Coupon':
      return l10n.tr('tns.zeroCoupon');
    case 'Other':
      return l10n.tr('tns.other');
    default:
      final translatedByValue = l10n.trBestEffort(option.value);
      if (translatedByValue != option.value) {
        return translatedByValue;
      }
      final translatedByLabel = l10n.trBestEffort(option.label);
      if (translatedByLabel != option.label) {
        return translatedByLabel;
      }
      return option.label;
  }
}

String _localizedContractTypeLabel(
  ContractsLookupOption option,
  AppLocalizations l10n,
) {
  switch (option.value) {
    case 'HOMEOWNERS_INSURANCE':
      return l10n.tr('tns.contractTypeHomeownersInsurance');
    case 'HOUSEHOLD_INSURANCE':
      return l10n.tr('tns.contractTypeHouseholdInsurance');
    case 'HOUSEHOLD_AND_HOME_INSURANCE':
      return l10n.tr('tns.contractTypeHouseholdAndHomeInsurance');
    case 'LEGAL_PROTECTION_INSURANCE':
      return l10n.tr('tns.contractTypeLegalProtectionInsurance');
    case 'CAR_INSURANCE':
      return l10n.tr('tns.contractTypeCarInsurance');
    case 'OTHER_INSURANCE':
      return l10n.tr('tns.contractTypeOtherInsurance');
    case 'BUILDING_SAVINGS':
      return l10n.tr('tns.contractTypeBuildingSavings');
    case 'SAVINGS_BOOK':
      return l10n.tr('tns.contractTypeSavingsBook');
    case 'SAVINGS_ACCOUNT_OR_CASH':
      return l10n.tr('tns.contractTypeSavingsAccountOrCash');
    case 'FIXED_DEPOSIT':
      return l10n.tr('tns.contractTypeFixedDeposit');
    case 'BONDS':
      return l10n.tr('tns.contractTypeBonds');
  }

  final normalized = option.label.toLowerCase().trim();
  if (normalized == 'homeowners insurance') {
    return l10n.tr('tns.contractTypeHomeownersInsurance');
  }
  if (normalized == 'household insurance') {
    return l10n.tr('tns.contractTypeHouseholdInsurance');
  }
  if (normalized == 'household and home insurance') {
    return l10n.tr('tns.contractTypeHouseholdAndHomeInsurance');
  }
  if (normalized == 'legal protection insurance') {
    return l10n.tr('tns.contractTypeLegalProtectionInsurance');
  }
  if (normalized == 'car insurance') {
    return l10n.tr('tns.contractTypeCarInsurance');
  }
  if (normalized == 'other insurance') {
    return l10n.tr('tns.contractTypeOtherInsurance');
  }
  final translatedByValue = l10n.trBestEffort(option.value);
  if (translatedByValue != option.value) {
    return translatedByValue;
  }
  final translatedByLabel = l10n.trBestEffort(option.label);
  if (translatedByLabel != option.label) {
    return translatedByLabel;
  }
  return option.label;
}

const List<ContractsLookupOption> _insuranceFrequencyOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'Monthly', value: 'Monthly'),
      ContractsLookupOption(label: 'Quarterly', value: 'Quarterly'),
      ContractsLookupOption(label: 'Half Yearly', value: 'Half Yearly'),
      ContractsLookupOption(label: 'Annually', value: 'Annually'),
      ContractsLookupOption(label: 'One Time', value: 'One Time'),
    ];

const List<ContractsLookupOption> _retirementFrequencyOptions =
    _insuranceFrequencyOptions;

List<ContractsLookupOption> _retirementStatusOptions(AppLocalizations l10n) =>
    <ContractsLookupOption>[
      ContractsLookupOption(label: l10n.tr('tns.active'), value: 'active'),
      ContractsLookupOption(label: l10n.tr('tns.inactive'), value: 'inactive'),
      ContractsLookupOption(label: l10n.tr('tns.unknown'), value: 'unknown'),
    ];

const List<ContractsLookupOption> _loanInterestTypeOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'Variable', value: 'Variable'),
      ContractsLookupOption(label: 'Fixed', value: 'Fixed'),
    ];

const List<ContractsLookupOption> _loanReferenceRateOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: '3-Month Euribor', value: '3-Month Euribor'),
      ContractsLookupOption(label: '6-Month Euribor', value: '6-Month Euribor'),
      ContractsLookupOption(
        label: '12-Month Euribor',
        value: '12-Month Euribor',
      ),
      ContractsLookupOption(label: 'Prime Rate', value: 'Prime Rate'),
    ];

const List<ContractsLookupOption> _investmentPaymentFrequencyOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'Monthly', value: 'Monthly'),
      ContractsLookupOption(label: 'Quarterly', value: 'Quarterly'),
      ContractsLookupOption(label: 'Annually', value: 'Annually'),
      ContractsLookupOption(label: 'Semi Annually', value: 'Semi Annually'),
      ContractsLookupOption(label: 'Once', value: 'Once'),
      ContractsLookupOption(label: 'other, unknown', value: 'other, unknown'),
    ];

const List<ContractsLookupOption> _couponTypeOptions = <ContractsLookupOption>[
  ContractsLookupOption(label: 'Fixed Rate', value: 'Fixed Rate'),
  ContractsLookupOption(label: 'Step-Up Rate', value: 'Step-Up Rate'),
  ContractsLookupOption(label: 'Variable Rate', value: 'Variable Rate'),
  ContractsLookupOption(label: 'Zero Coupon', value: 'Zero Coupon'),
];

const List<ContractsLookupOption> _currencyOptions = <ContractsLookupOption>[
  ContractsLookupOption(label: 'EUR', value: 'EUR'),
  ContractsLookupOption(label: 'CHF', value: 'CHF'),
  ContractsLookupOption(label: 'JPY', value: 'JPY'),
  ContractsLookupOption(label: 'USD', value: 'USD'),
  ContractsLookupOption(label: 'Other', value: 'Other'),
];

const List<ContractsLookupOption> _couponPeriodOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'Monthly', value: 'Monthly'),
      ContractsLookupOption(label: 'Quarterly', value: 'Quarterly'),
      ContractsLookupOption(label: 'Semi Annually', value: 'Semi Annually'),
      ContractsLookupOption(label: 'Annually', value: 'Annually'),
      ContractsLookupOption(label: 'One Time', value: 'One Time'),
    ];

const Set<String> _investmentBookValueDateTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'STOCKS',
  'BONDS',
};

const Set<String> _investmentNoBookValueDateTypes = <String>{
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
  'BUILDER_OWNER_MODEL',
  'BUILDING_SAVINGS',
  'SAVINGS_BOOK',
  'SAVINGS_ACCOUNT_OR_CASH',
  'FIXED_DEPOSIT',
};

const Set<String> _investmentTargetSumTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
  'STOCKS',
};

const Set<String> _investmentRiskTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
  'BONDS',
  'BUILDER_OWNER_MODEL',
};

const Set<String> _investmentIsinTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
  'STOCKS',
  'BONDS',
};

const Set<String> _investmentCurrentValueTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
  'STOCKS',
  'BONDS',
  'BUILDING_SAVINGS',
  'SAVINGS_BOOK',
  'SAVINGS_ACCOUNT_OR_CASH',
  'FIXED_DEPOSIT',
};

const Set<String> _investmentCurrentValueDateTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'STOCKS',
  'BONDS',
  'BUILDING_SAVINGS',
  'ASSET_ALLOCATION_FUNDS',
  'BOND_FUNDS',
};

const Set<String> _investmentCurrentShareValueTypes = <String>{
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
};

const Set<String> _investmentNumberOfSharesTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
  'STOCKS',
  'BUILDER_OWNER_MODEL',
};
