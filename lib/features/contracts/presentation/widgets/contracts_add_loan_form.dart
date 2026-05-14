import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_helpers.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_initial_data.dart';
import 'package:flutter/material.dart';

class ContractsAddLoanFormModal extends StatefulWidget {
  const ContractsAddLoanFormModal({
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
  State<ContractsAddLoanFormModal> createState() =>
      _ContractsAddLoanFormModalState();
}

class _ContractsAddLoanFormModalState
    extends State<ContractsAddLoanFormModal> {
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
    return _selectedType != null &&
        _tradeInValueController.text.trim().isNotEmpty;
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
      _fixedInterestDurationController.text =
          initial.fixedInterestRateDuration ?? '';
      _bankSurchargeController.text = initial.bankSurcharge ?? '';
      _selectedType = findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedInterestType = findLookupByAny(
        loanInterestTypeOptions,
        initial.interestTypeValueOrLabel,
      );
      _selectedReferenceRate = findLookupByAny(
        loanReferenceRateOptions,
        initial.referenceRateValueOrLabel,
      );
      _selectedPartner = findPartner(widget.partners, initial.partnerName);
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
      const <String>{'AND', 'BSD', 'TFD', 'LEA', 'SVF'}.contains(
        _selectedType!.value,
      );

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
      final amount = parseNumber(_amountController.text);
      final contractData = <String, dynamic>{
        'Title': nullIfBlank(_purposeController.text),
        'ContractNumber': nullIfBlank(_contractNumberController.text),
        'Amount': amount,
        'Type': _selectedType!.value,
        'InterestRate': null,
        'StartDate': toIsoDate(_startDate),
        'EndDate': toIsoDate(_endDate),
        'StartOfRepayment': toIsoDate(_startOfRepayment),
        'DateOfReaminingDept': _showsRemainingDebtDate
            ? toIsoDate(_remainingDebtDate)
            : null,
        'AdviserVisibility': true,
        'PartnerItemId': _selectedPartner?.itemId,
        'RemainingAmount': _showsRemainingAmount
            ? parseNumber(_remainingAmountController.text)
            : null,
        'PartnerName': _selectedPartner?.name,
        'InterestOnlyPeriod': null,
        'ResidualValue': null,
        'ValueOfTradeIn': parseNumber(_tradeInValueController.text),
        'PayableAmount': amount,
        'InterestAmount': null,
        'PaidTillNow': null,
        'AmountPayableAfterIOPeriod': null,
        'AmountLeft': amount,
        'Collateral': null,
        'ProductPartnerDescription': null,
        'Term': calculateTermMonth(_startDate, _endDate),
        'Language': Localizations.localeOf(context).languageCode,
        'Tags': const <String>['Is-A-Loan'],
        'TypeOfInterest': _selectedInterestType?.value,
        'FixedInterestRate': _showsFixedInterestFields
            ? parseNumber(_fixedInterestRateController.text)
            : null,
        'FixedInterestRateDuration': _showsFixedInterestFields
            ? parseNumber(_fixedInterestDurationController.text)?.toInt()
            : null,
        'ReferenceInterestRate': _selectedReferenceRate?.value,
        'BankSurcharge': parseNumber(_bankSurchargeController.text),
        'Notes': nullIfBlank(_notesController.text),
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
      showCreateFailedMessage(context);
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
              itemLabel: (item) => localizedContractTypeLabel(item, l10n),
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
              validator: (value) => requiredSelectionValidator(value, l10n),
              enabled: !isApiDisabledField(widget.initialData, 'Type'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.purposeOfUse'),
              controller: _purposeController,
              validator: (value) => textValidator(value, l10n, maxLength: 50),
              enabled: !isApiDisabledField(widget.initialData, 'PurposeOfUse'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractNumber'),
              controller: _contractNumberController,
              validator: (value) => textValidator(value, l10n, maxLength: 50),
              enabled: !isApiDisabledField(widget.initialData, 'ContractNumber'),
            ),
            ContractsDropdownField<ContractsPartnerOption>(
              label: l10n.tr('tns.bankingInstitute'),
              hint: l10n.tr('tns.selectPartner'),
              items: widget.partners,
              value: _selectedPartner,
              itemLabel: (item) => item.name,
              onChanged: (value) => setState(() => _selectedPartner = value),
              enabled: !isApiDisabledField(widget.initialData, 'PartnerName'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.loanAmount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) =>
                  numberValidator(value, l10n, min: 100, max: 9999999999),
              enabled: !isApiDisabledField(widget.initialData, 'Amount'),
            ),
            ContractsDateField(
              label: l10n.tr('tns.startOfRepayment'),
              value: _startOfRepayment,
              enabled: !isApiDisabledField(widget.initialData, 'StartOfRepayment'),
              onTap: () async {
                final value = await pickDate(context, _startOfRepayment);
                if (value != null) setState(() => _startOfRepayment = value);
              },
            ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.typeOfInterest'),
              hint: l10n.tr('tns.typeOfInterest'),
              items: loanInterestTypeOptions,
              value: _selectedInterestType,
              itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
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
                    numberValidator(value, l10n, min: 0.1, max: 25),
              ),
            if (_showsFixedInterestFields)
              ContractsTextField(
                label: l10n.tr('tns.fixedInterestRateDuration'),
                controller: _fixedInterestDurationController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                validator: (value) =>
                    numberValidator(value, l10n, min: 1, max: 50),
              ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.referenceInterestRate'),
              hint: l10n.tr('tns.referenceInterestRate'),
              items: loanReferenceRateOptions,
              value: _selectedReferenceRate,
              itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
              onChanged: (value) =>
                  setState(() => _selectedReferenceRate = value),
            ),
            ContractsTextField(
              label: l10n.tr('tns.bankSurcharge'),
              controller: _bankSurchargeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: '%',
              validator: (value) =>
                  numberValidator(value, l10n, min: 0.1, max: 25),
            ),
            ContractsTextField(
              label: l10n.tr('tns.tradeInValue'),
              required: true,
              controller: _tradeInValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) => numberValidator(
                value,
                l10n,
                required: true,
                min: 0,
                max: 9999999999,
              ),
              enabled: !isApiDisabledField(widget.initialData, 'ValueOfTradeIn'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.remainingLoan'),
              controller: _remainingAmountController,
              enabled: _showsRemainingAmount &&
                  !isApiDisabledField(widget.initialData, 'RemainingAmount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) => !_showsRemainingAmount
                  ? null
                  : numberValidator(
                      value,
                      l10n,
                      required: _remainingDebtDate != null,
                      min: 0,
                      max: 9999999999,
                    ),
            ),
            ContractsDateField(
              label: l10n.tr('tns.dateOfRemainingDebt'),
              required: !isEdit &&
                  _remainingAmountController.text.trim().isNotEmpty,
              value: _remainingDebtDate,
              enabled: _showsRemainingDebtDate &&
                  !isApiDisabledField(
                    widget.initialData,
                    'DateOfReaminingDept',
                  ),
              onTap: () async {
                final value = await pickDate(context, _remainingDebtDate);
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
              enabled: !isApiDisabledField(widget.initialData, 'StartDate'),
              onTap: () async {
                final value = await pickDate(context, _startDate);
                if (value != null) setState(() => _startDate = value);
              },
            ),
            ContractsDateField(
              label: l10n.tr('tns.endDate'),
              value: _endDate,
              enabled: !isApiDisabledField(widget.initialData, 'EndDate'),
              onTap: () async {
                final value = await pickDate(context, _endDate);
                if (value != null) setState(() => _endDate = value);
              },
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
