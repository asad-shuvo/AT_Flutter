enum ContractsAddKind { insurance, retirement, loan, investment }

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
