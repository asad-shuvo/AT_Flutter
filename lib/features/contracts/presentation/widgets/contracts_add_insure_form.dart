import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_helpers.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_initial_data.dart';
import 'package:flutter/material.dart';

class ContractsAddInsureFormModal extends StatefulWidget {
  const ContractsAddInsureFormModal({
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
  State<ContractsAddInsureFormModal> createState() =>
      _ContractsAddInsureFormModalState();
}

class _ContractsAddInsureFormModalState
    extends State<ContractsAddInsureFormModal> {
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
      _selectedType = findLookupByAny(widget.types, initial.typeValueOrLabel);
      _selectedFrequency = findLookupByAny(
        insuranceFrequencyOptions,
        initial.premiumFrequencyValueOrLabel,
      );
      _selectedPartner = findPartner(widget.partners, initial.partnerName);
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
        'ContractNumber': nullIfBlank(_contractNumberController.text),
        'Type': _selectedType!.label,
        'StartDate': toIsoDate(_startDate),
        'EndDate': toIsoDate(_endDate),
        'GrossPremium': parseNumber(_grossPremiumController.text),
        'PremiumFrequency': _selectedFrequency!.value,
        'MaturityBenefits': parseNumber(_maturityBenefitsController.text),
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
        'Notes': nullIfBlank(_notesController.text),
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
              label: l10n.tr('tns.investmentType'),
              required: true,
              hint: l10n.tr('tns.investmentType'),
              items: widget.types,
              value: _selectedType,
              itemLabel: (item) => localizedContractTypeLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) => requiredSelectionValidator(value, l10n),
              enabled: !isApiDisabledField(widget.initialData, 'Type'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.title'),
              required: true,
              controller: _titleController,
              validator: (value) =>
                  textValidator(value, l10n, required: true, maxLength: 50),
              enabled: !isApiDisabledField(widget.initialData, 'Title'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.contractNumber'),
              controller: _contractNumberController,
              validator: (value) => textValidator(value, l10n, maxLength: 50),
              enabled: !isApiDisabledField(widget.initialData, 'ContractNumber'),
            ),
            ContractsDropdownField<ContractsLookupOption>(
              label: l10n.tr('tns.premiumFrequency'),
              required: true,
              hint: l10n.tr('tns.premiumFrequency'),
              items: insuranceFrequencyOptions,
              value: _selectedFrequency,
              itemLabel: (item) => localizedStaticOptionLabel(item, l10n),
              onChanged: (value) => setState(() => _selectedFrequency = value),
              validator: (value) => requiredSelectionValidator(value, l10n),
              enabled: !isApiDisabledField(widget.initialData, 'PremiumFrequency'),
            ),
            ContractsTextField(
              label: l10n.tr('tns.grossPremium'),
              required: true,
              controller: _grossPremiumController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) => numberValidator(
                value,
                l10n,
                required: true,
                min: 0,
                max: 999999,
              ),
              enabled: !isApiDisabledField(widget.initialData, 'GrossPremium'),
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
            ContractsTextField(
              label: l10n.tr('tns.insuranceAmount'),
              controller: _maturityBenefitsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffixText: 'EUR',
              validator: (value) =>
                  numberValidator(value, l10n, min: 0, max: 999999),
              enabled: !isApiDisabledField(widget.initialData, 'MaturityBenefits'),
            ),
            ContractsDateField(
              label: l10n.tr('tns.startDate'),
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
