class InvestmentContractsData {
  const InvestmentContractsData({
    required this.totalCount,
    required this.currentPersonId,
    required this.contracts,
  });

  final int totalCount;
  final String currentPersonId;
  final List<InvestmentContract> contracts;
}

class InvestmentContract {
  const InvestmentContract({
    required this.itemId,
    required this.title,
    required this.iconCodePoint,
    required this.source,
    required this.personId,
    required this.partnerName,
    required this.investmentType,
    required this.bookValueDate,
    required this.investmentStartDate,
    required this.investmentBookValue,
    required this.investmentCurrentValue,
    required this.lumpSumInvestment,
    this.accountNumber,
    this.contractNumber,
    this.notes,
    this.investmentEndDate,
    this.paymentFrequency,
    this.isTargetSumSavingsPlan,
    this.risk,
    this.isin,
    this.numberOfShares,
    this.currentShareValue,
    this.interestRate,
    this.couponRate,
    this.couponType,
    this.iban,
    this.bic,
    this.currency,
    this.issuer,
    this.isPremiumBenefit,
    this.bondPrice,
    this.bondPriceDate,
    this.currentValueDate,
    this.lastUpdateDate,
    this.syncDisabledProperties,
  });

  final String itemId;
  final String? title;
  final int iconCodePoint;
  final String? source;
  final String? personId;
  final String? partnerName;
  final String? investmentType;
  final DateTime? bookValueDate;
  final DateTime? investmentStartDate;
  final double? investmentBookValue;
  final double? investmentCurrentValue;
  final double? lumpSumInvestment;
  final String? accountNumber;
  final String? contractNumber;
  final String? notes;
  final DateTime? investmentEndDate;
  final String? paymentFrequency;
  final bool? isTargetSumSavingsPlan;
  final double? risk;
  final String? isin;
  final double? numberOfShares;
  final double? currentShareValue;
  final double? interestRate;
  final double? couponRate;
  final String? couponType;
  final String? iban;
  final String? bic;
  final String? currency;
  final String? issuer;
  final bool? isPremiumBenefit;
  final double? bondPrice;
  final DateTime? bondPriceDate;
  final DateTime? currentValueDate;
  final DateTime? lastUpdateDate;
  final List<String>? syncDisabledProperties;

  double? get displayAmount {
    if (investmentCurrentValue != null) return investmentCurrentValue;
    if (lumpSumInvestment != null) return lumpSumInvestment;
    if (investmentBookValue != null) return investmentBookValue;
    if (investmentCurrentValue == 0 ||
        lumpSumInvestment == 0 ||
        investmentBookValue == 0) {
      return 0;
    }
    return investmentCurrentValue;
  }

  DateTime? get displayDate {
    if (investmentType == 'PORTFOLIO' || investmentType == 'INSTRUMENT') {
      return bookValueDate;
    }
    return investmentStartDate;
  }
}
