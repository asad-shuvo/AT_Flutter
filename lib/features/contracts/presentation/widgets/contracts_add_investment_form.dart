import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_helpers.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_initial_data.dart';
import 'package:flutter/material.dart';

class ContractsAddInvestmentFormModal extends StatefulWidget {
  const ContractsAddInvestmentFormModal({
    super.key,
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
  State<ContractsAddInvestmentFormModal> createState() =>
      _ContractsAddInvestmentFormModalState();
}

class _ContractsAddInvestmentFormModalState
    extends State<ContractsAddInvestmentFormModal> {
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
      _selectedType = findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedPaymentFrequency = findLookupByAny(
        investmentPaymentFrequencyOptions,
        initial.paymentFrequencyValueOrLabel,
      );
      _selectedCouponType = findLookupByAny(
        couponTypeOptions,
        initial.couponTypeValueOrLabel,
      );
      _selectedCouponPeriod = findLookupByAny(
        couponPeriodOptions,
        initial.couponPeriodValueOrLabel,
      );
      _selectedCurrency = findLookupByAny(
        currencyOptions,
        initial.currencyValueOrLabel,
      );
      _isTargetSumSavingsPlan = initial.isTargetSumSavingsPlan;
      _isPremiumBenefit = initial.isPremiumBenefit;
      _selectedPartner = findPartner(widget.partners, initial.partnerName);
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
      _typeIn(investmentBookValueDateTypes) &&
      !_typeIn(investmentNoBookValueDateTypes);
  bool get _showPaymentFrequency =>
      !_typeIn(const <String>{'FIXED_DEPOSIT'}) ||
      _typeIn(const <String>{'BUILDER_OWNER_MODEL', 'SAVINGS_BOOK'});
  bool get _showTargetSumSavingsPlan => _typeIn(investmentTargetSumTypes);
  bool get _showRisk => _typeIn(investmentRiskTypes);
  bool get _showIsin => _typeIn(investmentIsinTypes);
  bool get _showCurrentValue => _typeIn(investmentCurrentValueTypes);
  bool get _showCurrentValueDate => _typeIn(investmentCurrentValueDateTypes);
  bool get _showCurrentShareValue => _typeIn(investmentCurrentShareValueTypes);
  bool get _showNumberOfShares => _typeIn(investmentNumberOfSharesTypes);
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
    if (!_showAccountNumber) _accountNumberController.clear();
    if (!_showDateRange) {
      _investmentStartDate = null;
      _investmentEndDate = null;
    }
    if (!_showBookValueDate) _bookValueDate = null;
    if (!_showTargetSumSavingsPlan) _isTargetSumSavingsPlan = null;
    if (!_showRisk) _riskController.clear();
    if (!_showIsin) _isinController.clear();
    if (!_showCurrentValueDate) _currentValueDate = null;
    if (!_showCurrentShareValue) _currentShareValueController.clear();
    if (!_showNumberOfShares) _numberOfSharesController.clear();
    if (!_showCouponRate) _couponRateController.clear();
    if (!_showCouponPeriod) _selectedCouponPeriod = null;
    if (!_showCouponType) _selectedCouponType = null;
    if (!_showIssuer) _issuerController.clear();
    if (!_showBondPrice) {
      _bondPriceController.clear();
      _bondPriceDate = null;
    }
    if (!_showCurrency) _selectedCurrency = null;
    if (!_showIban) _ibanController.clear();
    if (!_showBic) _bicController.clear();
    if (!_showPremiumBenefit) _isPremiumBenefit = null;
    if (!_showInterestRate) _interestRateController.clear();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final contractData = <String, dynamic>{
        'Title': _titleController.text.trim(),
        'InvestmentBookValue': parseNumber(_investmentBookValueController.text),
        'InvestmentCurrentValue': parseNumber(
          _investmentCurrentValueController.text,
        ),
        'AccountNumber': _showAccountNumber
            ? nullIfBlank(_accountNumberController.text)
            : null,
        'PartnerItemId': _selectedPartner?.itemId,
        'PartnerName': _selectedPartner?.name,
        'ProductPartnerDescription': null,
        'InvestmentType': _selectedType!.label,
        'Notes': nullIfBlank(_notesController.text),
        'BookValueDate': _showBookValueDate ? toIsoDate(_bookValueDate) : null,
        'BondPriceDate': _showBondPriceDate ? toIsoDate(_bondPriceDate) : null,
        'CurrentValueDate': _showCurrentValueDate
            ? toIsoDate(_currentValueDate)
            : null,
        'InvestmentStartDate': _showDateRange
            ? toIsoDate(_investmentStartDate)
            : null,
        'InvestmentEndDate': _showDateRange
            ? toIsoDate(_investmentEndDate)
            : null,
        'PaymentFrequency': _selectedPaymentFrequency?.value,
        'IsTargetSumSavingsPlan': _showTargetSumSavingsPlan
            ? _isTargetSumSavingsPlan
            : null,
        'LumpSumInvestment': parseNumber(_lumpSumInvestmentController.text),
        'Risk': _showRisk ? parseNumber(_riskController.text) : null,
        'ISIN': _showIsin ? nullIfBlank(_isinController.text) : null,
        'NumberofShares': _showNumberOfShares
            ? parseNumber(_numberOfSharesController.text)
            : null,
        'CurrentShareValue': _showCurrentShareValue
            ? parseNumber(_currentShareValueController.text)
            : null,
        'InterestRate': _showInterestRate
            ? parseNumber(_interestRateController.text)
            : null,
        'CouponType': _showCouponType ? _selectedCouponType?.value : null,
        'CouponRate': _showCouponRate
            ? parseNumber(_couponRateController.text)
            : null,
        'IBAN': _showIban ? nullIfBlank(_ibanController.text) : null,
        'BIC': _showBic ? nullIfBlank(_bicController.text) : null,
        'Currency': _showCurrency ? _selectedCurrency?.value : null,
        'Issuer': _showIssuer ? nullIfBlank(_issuerController.text) : null,
        'IsPremiumBenefit': _showPremiumBenefit ? _isPremiumBenefit : null,
        'BondPrice': _showBondPrice
            ? parseNumber(_bondPriceController.text)
            : null,
        'CouponPeriod': _showCouponPeriod ? _selectedCouponPeriod?.value : null,
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
      showCreateFailedMessage(context);
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
              itemLabel: (item) => localizedContractTypeLabel(item, l10n),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                  _resetForTypeChange();
                });
              },
              validator: (value) => requiredSelectionValidator(value, l10n),
              enabled: !isApiDisabledField(widget.initialData, 'InvestmentType'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.title'),
              required: true,
              controller: _titleController,
              validator: (value) =>
                  textValidator(value, l10n, required: true, maxLength: 50),
              enabled: !isApiDisabledField(widget.initialData, 'Title'),
            ),
            ContractsDropdownField<ContractsPartnerOption>(
              label: l10n.tr('tns.productPartner'),
              hint: l10n.tr('tns.selectPartner'),
              items: widget.partners,
              value: _selectedPartner,
              itemLabel: (item) => item.name,
              onChanged: (value) => setState(() => _selectedPartner = value),
              enabled: !isApiDisabledField(widget.initialData, 'PartnerName'),
            ),
            if (_showAccountNumber)
              ContractsTextField(
                label: accountNumberLabel(l10n, _selectedTypeCode),
                controller: _accountNumberController,
                validator: (value) =>
                    textValidator(value, l10n, maxLength: 50),
                enabled: !isApiDisabledField(widget.initialData, 'AccountNumber'),
              ),
            if (_showDateRange)
              ContractsDateField(
                label: startDateLabel(l10n, _selectedTypeCode),
                value: _investmentStartDate,
                enabled: !isApiDisabledField(
                  widget.initialData,
                  'InvestmentStartDate',
                ),
                onTap: () async {
                  final value = await pickDate(context, _investmentStartDate);
                  if (value != null) {
                    setState(() => _investmentStartDate = value);
                  }
                },
              ),
            if (_showDateRange)
              ContractsDateField(
                label: endDateLabel(l10n, _selectedTypeCode),
                value: _investmentEndDate,
                enabled: !isApiDisabledField(
                  widget.initialData,
                  'InvestmentEndDate',
                ),
                onTap: () async {
                  final value = await pickDate(context, _investmentEndDate);
                  if (value != null) {
                    setState(() => _investmentEndDate = value);
                  }
                },
              ),
            const SizedBox(height: 6),
            ContractsFormSectionTitle(l10n.tr('tns.contractDetails')),
            ContractsTextField(
              label: bookValueLabel(l10n, _selectedTypeCode),
              controller: _investmentBookValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) =>
                  numberValidator(value, l10n, min: 0, max: 99999999),
              enabled: !isApiDisabledField(
                widget.initialData,
                'InvestmentBookValue',
              ),
            ),
            if (_showBookValueDate)
              ContractsDateField(
                label: bookValueDateLabel(l10n, _selectedTypeCode),
                value: _bookValueDate,
                onTap: () async {
                  final value = await pickDate(context, _bookValueDate);
                  if (value != null) setState(() => _bookValueDate = value);
                },
              ),
            if (_showPaymentFrequency)
              ContractsDropdownField<ContractsLookupOption>(
                label: paymentMethodLabel(l10n, _selectedTypeCode),
                hint: paymentMethodLabel(l10n, _selectedTypeCode),
                items: investmentPaymentFrequencyOptions,
                value: _selectedPaymentFrequency,
                itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
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
                    item ? l10n.tr('tns.yes') : l10n.tr('tns.no'),
                onChanged: (value) =>
                    setState(() => _isTargetSumSavingsPlan = value),
              ),
            ContractsTextField(
              label: l10n.tr('tns.lumpSumInvestment'),
              controller: _lumpSumInvestmentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) =>
                  numberValidator(value, l10n, min: 0, max: 99999999),
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
                    numberValidator(value, l10n, min: 0, max: 100),
              ),
            if (_showIsin)
              ContractsTextField(
                label: l10n.tr('tns.isin'),
                controller: _isinController,
                validator: (value) =>
                    textValidator(value, l10n, maxLength: 50),
                enabled: !isApiDisabledField(widget.initialData, 'ISIN'),
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
                    numberValidator(value, l10n, min: 0, max: 99999999),
                enabled: !isApiDisabledField(
                  widget.initialData,
                  'InvestmentCurrentValue',
                ),
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
                    numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            if (_showCurrentValueDate)
              ContractsDateField(
                label: l10n.tr('tns.currentValueDate'),
                value: _currentValueDate,
                onTap: () async {
                  final value = await pickDate(context, _currentValueDate);
                  if (value != null) setState(() => _currentValueDate = value);
                },
              ),
            if (_showNumberOfShares)
              ContractsTextField(
                label: l10n.tr('tns.numberofShares'),
                controller: _numberOfSharesController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    numberValidator(value, l10n, min: 0, max: 99999999),
                enabled: !isApiDisabledField(
                  widget.initialData,
                  'NumberofShares',
                ),
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
                    numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            if (_showCouponPeriod)
              ContractsDropdownField<ContractsLookupOption>(
                label: l10n.tr('COUPON_PERIOD'),
                hint: l10n.tr('COUPON_PERIOD'),
                items: couponPeriodOptions,
                value: _selectedCouponPeriod,
                itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
                onChanged: (value) =>
                    setState(() => _selectedCouponPeriod = value),
              ),
            if (_showCouponType)
              ContractsDropdownField<ContractsLookupOption>(
                label: l10n.tr('tns.couponType'),
                hint: l10n.tr('tns.couponType'),
                items: couponTypeOptions,
                value: _selectedCouponType,
                itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
                onChanged: (value) =>
                    setState(() => _selectedCouponType = value),
              ),
            if (_showIssuer)
              ContractsTextField(
                label: l10n.tr('tns.issuer'),
                controller: _issuerController,
                validator: (value) =>
                    textValidator(value, l10n, maxLength: 50),
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
                    numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            if (_showBondPriceDate)
              ContractsDateField(
                label: l10n.tr('tns.bondPriceDate'),
                value: _bondPriceDate,
                enabled: !isApiDisabledField(
                  widget.initialData,
                  'BondPriceDate',
                ),
                onTap: () async {
                  final value = await pickDate(context, _bondPriceDate);
                  if (value != null) setState(() => _bondPriceDate = value);
                },
              ),
            if (_showCurrency)
              ContractsDropdownField<ContractsLookupOption>(
                label: l10n.tr('tns.currency'),
                hint: l10n.tr('tns.currency'),
                items: currencyOptions,
                value: _selectedCurrency,
                itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
                onChanged: (value) => setState(() => _selectedCurrency = value),
              ),
            if (_showIban)
              ContractsTextField(
                label: l10n.tr('tns.iban'),
                controller: _ibanController,
                validator: (value) =>
                    textValidator(value, l10n, maxLength: 50),
              ),
            if (_showBic)
              ContractsTextField(
                label: l10n.tr('tns.bic'),
                controller: _bicController,
                validator: (value) =>
                    textValidator(value, l10n, maxLength: 50),
              ),
            if (_showPremiumBenefit)
              ContractsDropdownField<bool>(
                label: l10n.tr('tns.premiumBenefit'),
                hint: l10n.tr('tns.premiumBenefit'),
                items: const <bool>[true, false],
                value: _isPremiumBenefit,
                itemLabel: (item) =>
                    item ? l10n.tr('tns.yes') : l10n.tr('tns.no'),
                onChanged: (value) =>
                    setState(() => _isPremiumBenefit = value),
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
                    numberValidator(value, l10n, min: 0, max: 99999999),
              ),
            ContractsTextField(
              label: l10n.tr('tns.notes'),
              controller: _notesController,
              maxLines: 4,
              validator: (value) => textValidator(value, l10n, maxLength: 300),
            ),
          ],
        ),
      ),
    );
  }
}
