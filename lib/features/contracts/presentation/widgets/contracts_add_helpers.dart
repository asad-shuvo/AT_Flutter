import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_form_sheet.dart';
import 'package:filip_at_flutter/features/contracts/presentation/widgets/contracts_add_initial_data.dart';
import 'package:flutter/material.dart';

class ContractsAddBootstrapData {
  const ContractsAddBootstrapData({
    required this.types,
    required this.partners,
    this.fullContractDetails,
  });

  final List<ContractsLookupOption> types;
  final List<ContractsPartnerOption> partners;
  final Map<String, dynamic>? fullContractDetails;
}

String lookupEntityName(ContractsAddKind kind) {
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

String apiEntityName(ContractsAddKind kind) {
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

String titleKey(ContractsAddKind kind) {
  switch (kind) {
    case ContractsAddKind.insurance:
      return 'tns.insureModalHeader';
    case ContractsAddKind.retirement:
      return 'tns.addRetirementModalHeader';
    case ContractsAddKind.loan:
      return 'tns.loanModalHeader';
    case ContractsAddKind.investment:
      return 'tns.investmentModalHeader';
  }
}

String editTitleKey(ContractsAddKind kind) {
  switch (kind) {
    case ContractsAddKind.insurance:
      return 'tns.edit';
    case ContractsAddKind.retirement:
      return 'tns.editRetirementContract';
    case ContractsAddKind.loan:
      return 'tns.editLoanContract';
    case ContractsAddKind.investment:
      return 'tns.editInvestmentContract';
  }
}

bool isApiDisabledField(ContractsAddInitialData? initial, String field) {
  if (initial == null || !initial.isEdit) return false;
  final isDisabled = initial.syncDisabledProperties?.contains(field) ?? false;
  // ignore: avoid_print
  if (isDisabled) print('[contracts] Field "$field" is DISABLED by API');
  return isDisabled;
}

ContractsLookupOption? findLookupByAny(
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

ContractsPartnerOption? findPartner(
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

String? requiredSelectionValidator(Object? value, AppLocalizations l10n) {
  return value == null ? l10n.tr('tns.fieldRequired') : null;
}

String? textValidator(
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

String? numberValidator(
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

  final parsed = parseNumber(trimmed);
  if (parsed == null) {
    return l10n.tr('tns.enterValidNumber');
  }
  if (min != null && parsed < min) {
    return l10n.tr('tns.minimumValue', {'value': formatValidationNumber(min)});
  }
  if (max != null && parsed > max) {
    return l10n.tr('tns.maximumValue', {'value': formatValidationNumber(max)});
  }
  return null;
}

double? parseNumber(String? text) {
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

String? nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? toIsoDate(DateTime? value) {
  if (value == null) return null;
  return DateTime(value.year, value.month, value.day).toIso8601String();
}

String calculateTermYear(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return '0';
  return (endDate.year - startDate.year + 1).toString();
}

int calculateTermMonth(DateTime? startDate, DateTime? endDate) {
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

Future<DateTime?> pickDate(BuildContext context, DateTime? initialDate) {
  return showContractsWheelDatePicker(context, initialDate);
}

void showCreateFailedMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.tr('tns.contractCreateFailed'))),
  );
}

String formatValidationNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}

String bookValueLabel(AppLocalizations l10n, String typeName) {
  if (const <String>{'BONDS'}.contains(typeName)) {
    return l10n.tr('BOOK_VALUE_BOND');
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

String bookValueDateLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.priceDate')
      : l10n.tr('tns.valueAtOpening');
}

String startDateLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.purchaseDate')
      : l10n.tr('tns.startDate');
}

String endDateLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.maturityDate')
      : l10n.tr('tns.endDate');
}

String paymentMethodLabel(AppLocalizations l10n, String typeName) {
  return typeName == 'BONDS'
      ? l10n.tr('tns.paymentFrequency')
      : l10n.tr('tns.paymentMethod');
}

String accountNumberLabel(AppLocalizations l10n, String typeName) {
  if (typeName == 'BUILDING_SAVINGS') {
    return l10n.tr('tns.contractNumber');
  }
  return l10n.tr('tns.accountNumber');
}

String localizedStaticOptionLabel(
  ContractsLookupOption option,
  AppLocalizations l10n,
) {
  switch (option.value) {
    case 'Monthly':
      return l10n.tr('FREQ_MONTHLY');
    case 'Quarterly':
      return l10n.tr('FREQ_QUARTERLY');
    case 'Half Yearly':
      return l10n.tr('SEMI_ANNUALLY');
    case 'Annually':
      return l10n.tr('FREQ_ANNUALLY');
    case 'One Time':
      return l10n.tr('ONE_TIME');
    case 'Semi Annually':
      return l10n.tr('SEMI_ANNUALLY');
    case 'Once':
      return l10n.tr('ONCE');
    case 'other, unknown':
      return l10n.tr('OTHER');
    case 'Variable':
      return l10n.tr('VARIABLE');
    case 'Fixed':
      return l10n.tr('FIXED');
    case '3-Month Euribor':
      return l10n.tr('3_MONTH_EURIBOR');
    case '6-Month Euribor':
      return l10n.tr('6TH_MONTH_EURIBOR');
    case '12-Month Euribor':
      return l10n.tr('12TH_MONTH_EURIBOR');
    case 'Prime Rate':
      return l10n.tr('PRIME_RATE');
    case 'Fixed Rate':
      return l10n.tr('FIXED_RATE');
    case 'Step-Up Rate':
      return l10n.tr('STEPUP_RATE');
    case 'Variable Rate':
      return l10n.tr('VARIABLE_RATE');
    case 'Zero Coupon':
      return l10n.tr('ZERO_COUPON');
    case 'Other':
      return l10n.tr('OTHER');
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

String localizedContractTypeLabel(
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

const List<ContractsLookupOption> insuranceFrequencyOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'FREQ_MONTHLY', value: 'Monthly'),
      ContractsLookupOption(label: 'FREQ_QUARTERLY', value: 'Quarterly'),
      ContractsLookupOption(label: 'SEMI_ANNUALLY', value: 'Half Yearly'),
      ContractsLookupOption(label: 'FREQ_ANNUALLY', value: 'Annually'),
      ContractsLookupOption(label: 'FREQ_ONE_TIME', value: 'One Time'),
    ];

const List<ContractsLookupOption> retirementFrequencyOptions =
    insuranceFrequencyOptions;

List<ContractsLookupOption> retirementStatusOptions(AppLocalizations l10n) =>
    <ContractsLookupOption>[
      ContractsLookupOption(label: l10n.tr('ACTIVE'), value: 'active'),
      ContractsLookupOption(label: l10n.tr('INACTIVE'), value: 'inactive'),
      ContractsLookupOption(label: l10n.tr('UNKNOWN'), value: 'unknown'),
    ];

const List<ContractsLookupOption> loanInterestTypeOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'VARIABLE', value: 'Variable'),
      ContractsLookupOption(label: 'FIXED', value: 'Fixed'),
    ];

const List<ContractsLookupOption> loanReferenceRateOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: '3_MONTH_EURIBOR', value: '3-Month Euribor'),
      ContractsLookupOption(
        label: '6TH_MONTH_EURIBOR',
        value: '6-Month Euribor',
      ),
      ContractsLookupOption(
        label: '12TH_MONTH_EURIBOR',
        value: '12-Month Euribor',
      ),
      ContractsLookupOption(label: 'PRIME_RATE', value: 'Prime Rate'),
    ];

const List<ContractsLookupOption> investmentPaymentFrequencyOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'FREQ_MONTHLY', value: 'Monthly'),
      ContractsLookupOption(label: 'FREQ_QUARTERLY', value: 'Quarterly'),
      ContractsLookupOption(label: 'FREQ_ANNUALLY', value: 'Annually'),
      ContractsLookupOption(label: 'SEMI_ANNUALLY', value: 'Semi Annually'),
      ContractsLookupOption(label: 'ONCE', value: 'Once'),
      ContractsLookupOption(label: 'OTHER', value: 'other, unknown'),
    ];

const List<ContractsLookupOption> couponTypeOptions = <ContractsLookupOption>[
  ContractsLookupOption(label: 'FIXED_RATE', value: 'Fixed Rate'),
  ContractsLookupOption(label: 'STEPUP_RATE', value: 'Step-Up Rate'),
  ContractsLookupOption(label: 'VARIABLE_RATE', value: 'Variable Rate'),
  ContractsLookupOption(label: 'ZERO_COUPON', value: 'Zero Coupon'),
];

const List<ContractsLookupOption> currencyOptions = <ContractsLookupOption>[
  ContractsLookupOption(label: 'EUR', value: 'EUR'),
  ContractsLookupOption(label: 'CHF', value: 'CHF'),
  ContractsLookupOption(label: 'JPY', value: 'JPY'),
  ContractsLookupOption(label: 'USD', value: 'USD'),
  ContractsLookupOption(label: 'OTHER', value: 'Other'),
];

const List<ContractsLookupOption> couponPeriodOptions =
    <ContractsLookupOption>[
      ContractsLookupOption(label: 'FREQ_MONTHLY', value: 'Monthly'),
      ContractsLookupOption(label: 'FREQ_QUARTERLY', value: 'Quarterly'),
      ContractsLookupOption(label: 'SEMI_ANNUALLY', value: 'Semi Annually'),
      ContractsLookupOption(label: 'FREQ_ANNUALLY', value: 'Annually'),
      ContractsLookupOption(label: 'FREQ_ONE_TIME', value: 'One Time'),
    ];

const Set<String> investmentBookValueDateTypes = <String>{
  'PORTFOLIO',
  'INSTRUMENT',
  'EQUITY_FUND',
  'ALTERNATIVE_INVESTMENT',
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'STOCKS',
  'BONDS',
};

const Set<String> investmentNoBookValueDateTypes = <String>{
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

const Set<String> investmentTargetSumTypes = <String>{
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

const Set<String> investmentRiskTypes = <String>{
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

const Set<String> investmentIsinTypes = <String>{
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

const Set<String> investmentCurrentValueTypes = <String>{
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

const Set<String> investmentCurrentValueDateTypes = <String>{
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

const Set<String> investmentCurrentShareValueTypes = <String>{
  'BOND_FUNDS',
  'ASSET_ALLOCATION_FUNDS',
  'MONEY_MARKET_FUNDS',
  'REAL_ESTATE_FUNDS',
  'MIXED_FUNDS',
  'VALUE_PROTECTION',
  'OTHER_SPECIAL_INVESTMENTS',
};

const Set<String> investmentNumberOfSharesTypes = <String>{
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
