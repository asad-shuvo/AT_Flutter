class InvestmentOverview {
  const InvestmentOverview({
    this.personalPerformance,
    this.totalInvestment,
    this.investmentRisk,
    this.investorProfile,
    this.moneyMarketAccount,
    this.clearingAccount,
    this.fixedDepositAccounts,
  });

  final double? personalPerformance;
  final double? totalInvestment;
  final String? investmentRisk;
  final String? investorProfile;
  final double? moneyMarketAccount;
  final double? clearingAccount;
  final double? fixedDepositAccounts;
}
