import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_helpers.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_initial_data.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_insure_form.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_investment_form.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_loan_form.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_retirement_form.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_initial_data.dart';

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
    builder: (_) => _ContractsAddContractModal(
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
  late Future<ContractsAddBootstrapData> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    final isEditMode = widget.initialData?.isEdit == true;
    final cachedTypes = widget.repository.peekContractTypes(
      lookupEntityName(widget.kind),
    );
    final cachedPartners = widget.repository.peekPartners();

    if (!isEditMode && cachedTypes != null && cachedPartners != null) {
      _bootstrapFuture = SynchronousFuture<ContractsAddBootstrapData>(
        ContractsAddBootstrapData(
          types: cachedTypes,
          partners: cachedPartners,
          fullContractDetails: null,
        ),
      );
    } else {
      _bootstrapFuture = _loadBootstrap();
    }
  }

  Future<ContractsAddBootstrapData> _loadBootstrap() async {
    // ignore: avoid_print
    print('[contracts] Bootstrap started - isEdit=${widget.initialData?.isEdit}, contractId=${widget.initialData?.contractId}');

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      widget.repository.fetchContractTypes(lookupEntityName(widget.kind)),
      widget.repository.fetchPartners(),
      if (widget.initialData?.isEdit == true &&
          widget.initialData?.contractId != null)
        widget.repository.fetchContractDetails(
          contractEntityName: apiEntityName(widget.kind),
          contractItemId: widget.initialData!.contractId!,
        )
      else
        Future<dynamic>.value(null),
    ]);

    final fullDetails =
        results.length > 2 ? results[2] as Map<String, dynamic>? : null;
    // ignore: avoid_print
    print('[contracts] Bootstrap complete - fullDetails is ${fullDetails == null ? 'NULL' : 'POPULATED (${fullDetails.keys.length} keys)'}');

    return ContractsAddBootstrapData(
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
      typeValueOrLabel:
          initialData.typeValueOrLabel ?? _readString(fullDetails['Type']),
      title: initialData.title ?? _readString(fullDetails['Title']),
      contractNumber:
          initialData.contractNumber ?? _readString(fullDetails['ContractNumber']),
      partnerName:
          initialData.partnerName ?? _readString(fullDetails['PartnerName']),
      premiumFrequencyValueOrLabel: initialData.premiumFrequencyValueOrLabel ??
          _readString(fullDetails['PremiumFrequency']),
      paymentFrequencyValueOrLabel: initialData.paymentFrequencyValueOrLabel ??
          _readString(fullDetails['PaymentFrequency']),
      grossPremium: initialData.grossPremium ??
          _readDouble(fullDetails['GrossPremium'])?.toString(),
      insuranceAmount: initialData.insuranceAmount ??
          _readDouble(fullDetails['MaturityBenefits'])?.toString(),
      loanAmount: initialData.loanAmount ??
          _readDouble(fullDetails['Amount'])?.toString(),
      tradeInValue: initialData.tradeInValue ??
          _readDouble(fullDetails['ValueOfTradeIn'])?.toString(),
      accountNumber:
          initialData.accountNumber ?? _readString(fullDetails['AccountNumber']),
      bookValue: initialData.bookValue ??
          _readDouble(fullDetails['InvestmentBookValue'])?.toString(),
      currentValue: initialData.currentValue ??
          _readDouble(fullDetails['InvestmentCurrentValue'])?.toString(),
      lumpSumInvestment: initialData.lumpSumInvestment ??
          _readDouble(fullDetails['LumpSumInvestment'])?.toString(),
      notes: initialData.notes ?? _readString(fullDetails['Notes']),
      startDate:
          initialData.startDate ?? _readDateTime(fullDetails['StartDate']),
      endDate: initialData.endDate ?? _readDateTime(fullDetails['EndDate']),
      dueDate: initialData.dueDate ?? _readDateTime(fullDetails['DueDate']),
      bookValueDate:
          initialData.bookValueDate ?? _readDateTime(fullDetails['BookValueDate']),
      currentValueDate: initialData.currentValueDate ??
          _readDateTime(fullDetails['CurrentValueDate']),
      status: initialData.status ?? _readString(fullDetails['Status']),
      isin: initialData.isin ?? _readString(fullDetails['ISIN']),
      currentShareValue: initialData.currentShareValue ??
          _readDouble(fullDetails['CurrentShareValue'])?.toString(),
      numberOfShares: initialData.numberOfShares ??
          _readDouble(fullDetails['NumberofShares'])?.toString(),
      interestRate: initialData.interestRate ??
          _readDouble(fullDetails['InterestRate'])?.toString(),
      couponRate: initialData.couponRate ??
          _readDouble(fullDetails['CouponRate'])?.toString(),
      couponTypeValueOrLabel: initialData.couponTypeValueOrLabel ??
          _readString(fullDetails['CouponType']),
      couponPeriodValueOrLabel: initialData.couponPeriodValueOrLabel ??
          _readString(fullDetails['CouponPeriod']),
      currencyValueOrLabel: initialData.currencyValueOrLabel ??
          _readString(fullDetails['Currency']),
      issuer: initialData.issuer ?? _readString(fullDetails['Issuer']),
      bondPrice: initialData.bondPrice ??
          _readDouble(fullDetails['BondPrice'])?.toString(),
      bondPriceDate:
          initialData.bondPriceDate ?? _readDateTime(fullDetails['BondPriceDate']),
      risk: initialData.risk ?? _readDouble(fullDetails['Risk'])?.toString(),
      isTargetSumSavingsPlan: initialData.isTargetSumSavingsPlan ??
          (fullDetails['IsTargetSumSavingsPlan'] is bool
              ? fullDetails['IsTargetSumSavingsPlan'] as bool
              : null),
      isPremiumBenefit: initialData.isPremiumBenefit ??
          (fullDetails['IsPremiumBenefit'] is bool
              ? fullDetails['IsPremiumBenefit'] as bool
              : null),
      iban: initialData.iban ?? _readString(fullDetails['IBAN']),
      bic: initialData.bic ?? _readString(fullDetails['BIC']),
      interestTypeValueOrLabel: initialData.interestTypeValueOrLabel ??
          _readString(fullDetails['TypeOfInterest']),
      fixedInterestRate: initialData.fixedInterestRate ??
          _readDouble(fullDetails['FixedInterestRate'])?.toString(),
      fixedInterestRateDuration: initialData.fixedInterestRateDuration ??
          _readInt(fullDetails['FixedInterestRateDuration'])?.toString(),
      referenceRateValueOrLabel: initialData.referenceRateValueOrLabel ??
          _readString(fullDetails['ReferenceInterestRate']),
      bankSurcharge: initialData.bankSurcharge ??
          _readDouble(fullDetails['BankSurcharge'])?.toString(),
      remainingAmount: initialData.remainingAmount ??
          _readDouble(fullDetails['RemainingAmount'])?.toString(),
      remainingDebtDate: initialData.remainingDebtDate ??
          _readDateTime(fullDetails['DateOfReaminingDept']),
      startOfRepayment: initialData.startOfRepayment ??
          _readDateTime(fullDetails['StartOfRepayment']),
      syncDisabledProperties: initialData.syncDisabledProperties ??
          _readStringList(fullDetails['SyncDisabledProperties']),
      isLifeTime: initialData.isLifeTime ??
          (fullDetails['IsLifeTime'] is bool
              ? fullDetails['IsLifeTime'] as bool
              : null),
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
    return FutureBuilder<ContractsAddBootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final l10n = context.l10n;
        final title = widget.initialData?.isEdit == true
            ? l10n.tr(editTitleKey(widget.kind))
            : l10n.tr(titleKey(widget.kind));
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
            submitLabel: l10n.tr('tns.retry'),
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
            return ContractsAddInsureFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
          case ContractsAddKind.retirement:
            return ContractsAddRetirementFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
          case ContractsAddKind.loan:
            return ContractsAddLoanFormModal(
              repository: widget.repository,
              title: title,
              submitLabel: submitLabel,
              types: data.types,
              partners: data.partners,
              initialData: enrichedInitialData,
            );
          case ContractsAddKind.investment:
            return ContractsAddInvestmentFormModal(
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
