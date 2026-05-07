class InsureContractsData {
  const InsureContractsData({
    required this.totalCount,
    required this.currentPersonId,
    required this.contracts,
  });

  final int totalCount;
  final String currentPersonId;
  final List<InsureContract> contracts;
}

class InsureContract {
  const InsureContract({
    required this.itemId,
    required this.title,
    required this.type,
    required this.iconCodePoint,
    required this.endDate,
    required this.grossPremium,
    required this.source,
    required this.personId,
    required this.partnerName,
    required this.insuredPersons,
    this.contractNumber,
    this.startDate,
    this.premiumFrequency,
    this.maturityBenefits,
    this.isLifeTime,
    this.status,
    this.adviserVisibility,
    this.partnerId,
    this.partnerItemId,
    this.productPartnerDescription,
    this.notes,
    this.dueDate,
    this.vunr,
    this.lastUpdateDate,
    this.syncDisabledProperties,
  });

  final String itemId;
  final String? title;
  final String? type;
  final int iconCodePoint;
  final DateTime? endDate;
  final double? grossPremium;
  final String? source;
  final String? personId;
  final String? partnerName;
  final List<String> insuredPersons;
  final String? contractNumber;
  final DateTime? startDate;
  final String? premiumFrequency;
  final double? maturityBenefits;
  final bool? isLifeTime;
  final String? status;
  final bool? adviserVisibility;
  final String? partnerId;
  final String? partnerItemId;
  final String? productPartnerDescription;
  final String? notes;
  final DateTime? dueDate;
  final String? vunr;
  final DateTime? lastUpdateDate;
  final List<String>? syncDisabledProperties;
}

class InsureOverview {
  const InsureOverview({
    required this.totalContracts,
    required this.monthlyPremium,
    required this.annualPremium,
  });

  final int totalContracts;
  final double monthlyPremium;
  final double annualPremium;
}
