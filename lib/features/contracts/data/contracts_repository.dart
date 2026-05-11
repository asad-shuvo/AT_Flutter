import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_add_models.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_household_model.dart';
import 'package:filip_at_flutter/features/contracts/data/insure_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_contract_model.dart';
import 'package:filip_at_flutter/features/contracts/data/investment_overview_model.dart';

class ContractsRepository {
  ContractsRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
  }) : _apiClient = apiClient,
       _sessionCache = userSessionCache;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;
  final Map<String, List<ContractsLookupOption>> _contractTypesCache =
      <String, List<ContractsLookupOption>>{};
  List<ContractsPartnerOption>? _partnersCache;

  List<ContractsLookupOption>? peekContractTypes(String entityName) {
    return _contractTypesCache[entityName];
  }

  List<ContractsPartnerOption>? peekPartners() {
    return _partnersCache;
  }

  void clearLookupCaches() {
    _contractTypesCache.clear();
    _partnersCache = null;
  }

  Future<void> prewarmAddContractLookups() async {
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        fetchContractTypes('Insure'),
        fetchContractTypes('Retirement'),
        fetchContractTypes('Loan'),
        fetchContractTypes('Investment'),
        fetchPartners(),
      ]);
    } catch (_) {
      // Keep lazy flow if prewarm fails.
    }
  }

  Future<ContractsHouseholdData?> fetchHouseholdData() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || context.customerId.isEmpty) return null;

    final response = await _apiClient.postJson(
      url:
          '${_apiClient.snQueryUrl}SelectNetworkQuery/GetMyHouseholdAndBusiness',
      body: <String, dynamic>{
        'CustomerId': context.customerId,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    if (data is! Map<String, dynamic>) return null;

    final loggedInMember = ContractsHouseholdMember(
      personId: _readString(data['PersonId']) ?? context.personId,
      customerId: context.customerId,
      displayName:
          _readString(data['DisplayName']) ?? context.displayName ?? '',
      avatarColorValue: _parseColorHex(
        _readString(data['ColorCode']),
        fallback: 0xFFD82034,
      ),
      isCurrentUser: true,
      profileImageUrl: _apiClient.resolveProfileImageUrl(
        _readString(data['ProfileImage']),
      ),
      email: _readString(data['Email']),
      phoneNumber: _readString(data['PhoneNumber']),
      proposedUserId: _readString(data['ProposedUserId']),
      managerNr: _readString(data['ManagerNr']),
      totalContracts: _readInt(data['TotalContracts']),
      isSelected: true,
    );

    final householdMembers = <ContractsHouseholdMember>[
      loggedInMember,
      ..._mapHouseholdMembers(
        data['HouseholdMemberList'],
        selectedPersonIds: <String>{loggedInMember.personId},
        currentPersonId: loggedInMember.personId,
      ),
    ];
    final businessMembers = _filterBusinessMembers(
      _mapHouseholdMembers(
        data['BusinessList'],
        selectedPersonIds: const <String>{},
        currentPersonId: loggedInMember.personId,
      ),
      householdMembers: householdMembers,
      currentPersonId: loggedInMember.personId,
    );

    return ContractsHouseholdData(
      currentPersonId: context.personId,
      currentCustomerId: context.customerId,
      householdMembers: householdMembers,
      businessMembers: businessMembers,
    );
  }

  Future<void> syncContractsData({
    required List<String> personIds,
    bool forceSync = false,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return;

    final response = await _apiClient.postJson(
      url:
          '${_apiClient.slsnBusinessUrl}ExternalDataSyncCommand/SyncCustomerKvvContract',
      body: <String, dynamic>{
        'PersonIds': personIds.isEmpty ? <String>[context.personId] : personIds,
        'CustomerPersonId': context.personId,
        if (forceSync) 'ForceSync': true,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to sync contracts data.');
    }
  }

  Future<void> syncInvestmentContracts({
    required List<String> personIds,
    bool forceSync = false,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return;

    final selectedPersonIds = personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    await Future.wait<void>(<Future<void>>[
      syncContractsData(personIds: selectedPersonIds, forceSync: forceSync),
      _syncCustomerAdditiveContracts(
        context: context,
        personIds: selectedPersonIds,
        forceSync: forceSync,
      ),
    ]);
  }

  Future<void> syncCustomerDataById({
    required String customerId,
    required String userId,
    required String userName,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return;

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/SyncCustomerDataById',
      body: <String, dynamic>{
        'CustomerId': customerId,
        'NotifyUserId': userId,
        'NotifyUserName': userName,
        'CallerContext': 'KVV_SYNC',
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to sync customer data.');
    }
  }

  Future<void> syncCustomerDocument({
    required String customerId,
    required String userId,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return;

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/DownloadCustomerDocuments',
      body: <String, dynamic>{
        'Pnr': customerId,
        'UserId': userId,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to sync customer document.');
    }
  }

  Future<void> sendLeaveHouseholdEmail() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || context.customerId.isEmpty) return;

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/SendLeaveHouseHoldEmail',
      body: <String, dynamic>{
        'Pnr': context.customerId,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to send leave household email.');
    }
  }

  Future<InvestmentOverview?> fetchInvestmentOverview({
    List<String>? personIds,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;
    final headers = _authorizedHeaders(context.accessToken);

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _apiClient.postJson(
        url: '${_apiClient.snQueryUrl}ContractsQuery/GetInvestmentOverview',
        body: <String, dynamic>{
          'CustomerPersonId': context.personId,
          'PersonIds': selectedPersonIds,
          'MessageCorrelationId': _newGuid(),
        },
        headers: headers,
      ),
      _apiClient.postJson(
        url: '${_apiClient.snQueryUrl}ContractsQuery/GetInvestmentRiskProfile',
        body: <String, dynamic>{
          'CustomerPersonId': context.personId,
          'PersonIds': selectedPersonIds,
          'MessageCorrelationId': _newGuid(),
        },
        headers: headers,
      ),
    ]);

    final overviewResponse = results[0] as Map<String, dynamic>;
    final riskResponse = results[1] as Map<String, dynamic>;

    final overviewBody =
        overviewResponse['body'] as Map<String, dynamic>? ?? {};
    final riskBody = riskResponse['body'] as Map<String, dynamic>? ?? {};

    final overviewData = overviewBody['Data'];
    final overviewList = overviewData is Map
        ? overviewData['InvestmentOverviews']
        : null;

    double? personalPerformance;
    double? totalInvestment;
    double? moneyMarketAccount;
    double? clearingAccount;
    double? fixedDepositAccounts;
    double? volatility;

    if (overviewList is List) {
      for (final item in overviewList) {
        if (item is! Map) continue;
        final info = item['InvestmentOverviewMainInfo'];
        if (info is! Map) continue;

        final cumPerf = _readDouble(info['CumulativeCurrentPerformance']);
        if (cumPerf != null)
          personalPerformance = (personalPerformance ?? 0) + cumPerf;

        final currentVal = _readDouble(info['CurrentValue']);
        if (currentVal != null)
          totalInvestment = (totalInvestment ?? 0) + currentVal;

        final clearing = _readDouble(info['ClearingBalance']);
        if (clearing != null)
          clearingAccount = (clearingAccount ?? 0) + clearing;

        final konto = _readDouble(info['KontoPlusBalance']);
        if (konto != null)
          moneyMarketAccount = (moneyMarketAccount ?? 0) + konto;

        final fixed = _readDouble(info['FixedTermDepositBalance']);
        if (fixed != null)
          fixedDepositAccounts = (fixedDepositAccounts ?? 0) + fixed;

        final vol = _readDouble(
          info['ConsolidatedExistingPortfoliosVolatility'],
        );
        if (vol != null) volatility = vol;
      }
    }

    final riskData = riskBody['Data'];
    final riskList = riskData is Map
        ? riskData['InvestmentRiskProfiles']
        : null;
    String? investorProfile;
    if (riskList is List && riskList.isNotEmpty) {
      final first = riskList.first;
      if (first is Map) {
        final rp = first['RiskProfile'];
        if (rp is String) investorProfile = rp;
      }
    }

    return InvestmentOverview(
      personalPerformance: personalPerformance,
      totalInvestment: totalInvestment,
      investmentRisk: _volatilityToRisk(volatility),
      investorProfile: investorProfile,
      moneyMarketAccount: moneyMarketAccount,
      clearingAccount: clearingAccount,
      fixedDepositAccounts: fixedDepositAccounts,
    );
  }

  Future<InvestmentContractsData?> fetchInvestmentContracts({
    List<String>? personIds,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContracts',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Investment',
        'ExcludeCount': false,
        'Pagination': <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
        'Sort': <String, dynamic>{'SortBy': 'CreateDate', 'SortOrder': 'desc'},
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final totalCount = body['TotalCount'] is int
        ? body['TotalCount'] as int
        : int.tryParse('${body['TotalCount'] ?? 0}') ?? 0;
    final data = body['Data'];
    final investments = data is Map<String, dynamic>
        ? data['Investments']
        : null;

    if (investments is! List) {
      return InvestmentContractsData(
        totalCount: totalCount,
        currentPersonId: context.personId,
        contracts: const <InvestmentContract>[],
      );
    }

    return InvestmentContractsData(
      totalCount: totalCount,
      currentPersonId: context.personId,
      contracts: investments
          .whereType<Map>()
          .map(
            (item) => InvestmentContract(
              itemId: _readString(item['ItemId']) ?? '',
              title: _readString(item['Title']),
              iconCodePoint: _investmentTypeIconCodePoint(
                _readString(item['InvestmentType']),
              ),
              source: _readString(item['Source']),
              personId: _readString(item['PersonId']),
              partnerName: _readString(item['PartnerName']),
              investmentType: _readString(item['InvestmentType']),
              bookValueDate: _readDateTime(item['BookValueDate']),
              investmentStartDate: _readDateTime(item['InvestmentStartDate']),
              investmentBookValue: _readDouble(item['InvestmentBookValue']),
              investmentCurrentValue: _readDouble(
                item['InvestmentCurrentValue'],
              ),
              lumpSumInvestment: _readDouble(item['LumpSumInvestment']),
              accountNumber: _readString(item['AccountNumber']),
              contractNumber: _readString(item['ContractNumber']),
              notes: _readString(item['Notes']),
              lastUpdateDate: _readDateTime(item['LastUpdateDate']),
              investmentEndDate: _readDateTime(item['InvestmentEndDate']),
              paymentFrequency: _readString(item['PaymentFrequency']),
              isTargetSumSavingsPlan: item['IsTargetSumSavingsPlan'] is bool ? item['IsTargetSumSavingsPlan'] as bool : null,
              risk: _readDouble(item['Risk']),
              isin: _readString(item['ISIN']),
              numberOfShares: _readDouble(item['NumberofShares']),
              currentShareValue: _readDouble(item['CurrentShareValue']),
              interestRate: _readDouble(item['InterestRate']),
              couponRate: _readDouble(item['CouponRate']),
              couponType: _readString(item['CouponType']),
              iban: _readString(item['IBAN']),
              bic: _readString(item['BIC']),
              currency: _readString(item['Currency']),
              issuer: _readString(item['Issuer']),
              isPremiumBenefit: item['IsPremiumBenefit'] is bool ? item['IsPremiumBenefit'] as bool : null,
              bondPrice: _readDouble(item['BondPrice']),
              bondPriceDate: _readDateTime(item['BondPriceDate']),
              currentValueDate: _readDateTime(item['CurrentValueDate']),
              syncDisabledProperties: _readStringList(item['SyncDisabledProperties']),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<InsureOverview?> fetchNonLifeInsureOverview({
    List<String>? personIds,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContractOverview',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Insure',
        'ExcludeMonthlyChartData': true,
        'Tags': <String>['Is-A-Non-Life-Insure'],
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    final overview = data is Map<String, dynamic> ? data['Overview'] : null;
    if (overview is! Map) return null;

    return InsureOverview(
      totalContracts: _readInt(overview['TotalContracts']) ?? 0,
      monthlyPremium: _readDouble(overview['MonthlyPremium']) ?? 0,
      annualPremium: _readDouble(overview['AnnualPremium']) ?? 0,
    );
  }

  Future<InsureContractsData?> fetchNonLifeInsureContracts({
    List<String>? personIds,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContracts',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Insure',
        'Tag': 'Is-A-Non-Life-Insure',
        'ExcludeCount': false,
        'Pagination': <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
        'Sort': <String, dynamic>{'SortBy': 'CreateDate', 'SortOrder': 'desc'},
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final totalCount = _readInt(body['TotalCount']) ?? 0;
    final data = body['Data'];
    final insures = data is Map<String, dynamic> ? data['Insures'] : null;

    if (insures is! List) {
      return InsureContractsData(
        totalCount: totalCount,
        currentPersonId: context.personId,
        contracts: const <InsureContract>[],
      );
    }

    return InsureContractsData(
      totalCount: totalCount,
      currentPersonId: context.personId,
      contracts: insures
          .whereType<Map>()
          .map(
            (item) => InsureContract(
              itemId: _readString(item['ItemId']) ?? '',
              title: _readString(item['Title']),
              type: _readString(item['Type']),
              iconCodePoint: _insureTypeIconCodePoint(
                _readString(item['Type']),
              ),
              endDate: _readDateTime(item['EndDate']),
              grossPremium: _readDouble(item['GrossPremium']),
              source: _readString(item['Source']),
              personId: _readString(item['PersonId']),
              partnerName: _readString(item['PartnerName']),
              insuredPersons: _readStringList(item['InsuredPersons']),
              contractNumber: _readString(item['ContractNumber']),
              startDate: _readDateTime(item['StartDate']),
              premiumFrequency: _readString(item['PremiumFrequency']),
              maturityBenefits: _readDouble(item['MaturityBenefits']),
              isLifeTime: item['IsLifeTime'] is bool ? item['IsLifeTime'] as bool : null,
              status: _readString(item['Status']),
              adviserVisibility: item['AdviserVisibility'] is bool ? item['AdviserVisibility'] as bool : null,
              partnerId: _readString(item['PartnerId']),
              partnerItemId: _readString(item['PartnerItemId']),
              productPartnerDescription: _readString(item['ProductPartnerDescription']),
              notes: _readString(item['Notes']),
              lastUpdateDate: _readDateTime(item['LastUpdateDate']),
              vunr: _readString(item['Vunr']),
              syncDisabledProperties: _readStringList(item['SyncDisabledProperties']),
              dueDate: _readDateTime(item['DueDate']),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<InsureOverview?> fetchRetirementOverview({
    List<String>? personIds,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContractOverview',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Insure',
        'ExcludeMonthlyChartData': true,
        'Tags': <String>['Is-A-Life-Insure'],
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    final overview = data is Map<String, dynamic> ? data['Overview'] : null;
    if (overview is! Map) return null;

    return InsureOverview(
      totalContracts: _readInt(overview['TotalContracts']) ?? 0,
      monthlyPremium: _readDouble(overview['MonthlyPremium']) ?? 0,
      annualPremium: _readDouble(overview['AnnualPremium']) ?? 0,
    );
  }

  Future<InsureContractsData?> fetchRetirementContracts({
    List<String>? personIds,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContracts',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Insure',
        'Tag': 'Is-A-Life-Insure',
        'ExcludeCount': false,
        'Pagination': <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
        'Sort': <String, dynamic>{
          'SortBy': 'LastUpdateDate',
          'SortOrder': 'desc',
        },
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final totalCount = _readInt(body['TotalCount']) ?? 0;
    final data = body['Data'];
    final insures = data is Map<String, dynamic> ? data['Insures'] : null;

    if (insures is! List) {
      return InsureContractsData(
        totalCount: totalCount,
        currentPersonId: context.personId,
        contracts: const <InsureContract>[],
      );
    }

    return InsureContractsData(
      totalCount: totalCount,
      currentPersonId: context.personId,
      contracts: insures
          .whereType<Map>()
          .map(
            (item) => InsureContract(
              itemId: _readString(item['ItemId']) ?? '',
              title: _readString(item['Title']),
              type: _readString(item['Type']),
              iconCodePoint: _retirementTypeIconCodePoint(
                _readString(item['Type']),
              ),
              endDate: _readDateTime(item['EndDate']),
              grossPremium: _readDouble(item['GrossPremium']),
              source: _readString(item['Source']),
              personId: _readString(item['PersonId']),
              partnerName: _readString(item['PartnerName']),
              insuredPersons: _readStringList(item['InsuredPersons']),
              contractNumber: _readString(item['ContractNumber']),
              startDate: _readDateTime(item['StartDate']),
              premiumFrequency: _readString(item['PremiumFrequency']),
              maturityBenefits: _readDouble(item['MaturityBenefits']),
              isLifeTime: item['IsLifeTime'] is bool ? item['IsLifeTime'] as bool : null,
              status: _readString(item['Status']),
              adviserVisibility: item['AdviserVisibility'] is bool ? item['AdviserVisibility'] as bool : null,
              partnerId: _readString(item['PartnerId']),
              partnerItemId: _readString(item['PartnerItemId']),
              productPartnerDescription: _readString(item['ProductPartnerDescription']),
              notes: _readString(item['Notes']),
              lastUpdateDate: _readDateTime(item['LastUpdateDate']),
              dueDate: _readDateTime(item['DueDate']),
              syncDisabledProperties: _readStringList(item['SyncDisabledProperties']),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<InsureOverview?> fetchLoanOverview({List<String>? personIds}) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContractOverview',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Loan',
        'ExcludeMonthlyChartData': true,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    final overview = data is Map<String, dynamic> ? data['Overview'] : null;
    if (overview is! Map) return null;

    return InsureOverview(
      totalContracts: _readInt(overview['TotalContracts']) ?? 0,
      monthlyPremium: _readDouble(overview['MonthlyInstalment']) ?? 0,
      annualPremium: _readDouble(overview['TotalLoan']) ?? 0,
    );
  }

  Future<InsureContractsData?> fetchLoanContracts({
    List<String>? personIds,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return null;

    final selectedPersonIds = personIds == null || personIds.isEmpty
        ? <String>[context.personId]
        : personIds;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContracts',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': selectedPersonIds,
        'ContractEntityName': 'Loan',
        'ExcludeCount': false,
        'Pagination': <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
        'Sort': <String, dynamic>{'SortBy': 'CreateDate', 'SortOrder': 'desc'},
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final totalCount = _readInt(body['TotalCount']) ?? 0;
    final data = body['Data'];
    final loans = data is Map<String, dynamic> ? data['Loans'] : null;

    if (loans is! List) {
      return InsureContractsData(
        totalCount: totalCount,
        currentPersonId: context.personId,
        contracts: const <InsureContract>[],
      );
    }

    return InsureContractsData(
      totalCount: totalCount,
      currentPersonId: context.personId,
      contracts: loans
          .whereType<Map>()
          .map(
            (item) => InsureContract(
              itemId: _readString(item['ItemId']) ?? '',
              title: _readString(item['Title']),
              type: _readString(item['Type']),
              iconCodePoint: _loanTypeIconCodePoint(_readString(item['Type'])),
              endDate:
                  _readDateTime(item['DateOfReaminingDept']) ??
                  _readDateTime(item['StartDate']),
              grossPremium:
                  _readDouble(item['RemainingAmount']) ??
                  _readDouble(item['Amount']),
              source: _readString(item['Source']),
              personId: _readString(item['PersonId']),
              partnerName: _readString(item['PartnerName']),
              lastUpdateDate: _readDateTime(item['LastUpdateDate']),
              insuredPersons: _readStringList(item['InsuredPersons']),
              syncDisabledProperties: _readStringList(item['SyncDisabledProperties']),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>?> fetchContractDetails({
    required String contractEntityName,
    required String contractItemId,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || contractItemId.isEmpty) return null;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContractDetails',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'ContractEntityName': contractEntityName,
        'ContractItemId': contractItemId,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    // ignore: avoid_print
    print('[contracts-repo] fetchContractDetails response statusCode=$statusCode, entity=$contractEntityName, itemId=$contractItemId');
    if (statusCode < 200 || statusCode >= 300) {
      // ignore: avoid_print
      print('[contracts-repo] fetchContractDetails failed: statusCode=$statusCode, response=$response');
      return null;
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    if (data is! Map<String, dynamic>) {
      // ignore: avoid_print
      print('[contracts-repo] fetchContractDetails returned no data or invalid data');
      return null;
    }

    // ignore: avoid_print
    print('[contracts-repo] fetchContractDetails SUCCESS: ${data.keys}');
    return data;
  }

  Future<Map<String, dynamic>?> fetchRetirementContractDetails({
    required String contractItemId,
    String? personId,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || contractItemId.isEmpty) return null;
    final targetPersonId = (personId != null && personId.isNotEmpty)
        ? personId
        : context.personId;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContracts',
      body: <String, dynamic>{
        'PersonIds': <String>[targetPersonId],
        'ContractEntityName': 'Insure',
        'ExcludeCount': true,
        'ItemIds': <String>[contractItemId],
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      return null;
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    final insures = data is Map<String, dynamic> ? data['Insures'] : null;
    if (insures is! List || insures.isEmpty) return null;

    final first = insures.first;
    if (first is! Map<String, dynamic>) return null;
    return first;
  }

  Future<List<ContractDocument>> fetchContractDocuments({
    required String contractItemId,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || contractItemId.isEmpty) {
      return const <ContractDocument>[];
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/GetSourceDocument',
      body: <String, dynamic>{
        'SourceId': contractItemId,
        'IsArchived': false,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      return const <ContractDocument>[];
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final documents = body['Document'];
    if (documents is! List) return const <ContractDocument>[];

    return documents
        .whereType<Map>()
        .map((item) {
          final metaData = item['MetaData'];
          String? name;
          DateTime? uploadDate;
          if (metaData is Map) {
            final docId = metaData['DocumentId'];
            if (docId is Map) name = _readString(docId['Value']);
            final extDate = metaData['ExternalDocumentCreateDate'];
            if (extDate is Map) uploadDate = _readDateTime(extDate['Value']);
          }
          final createDateStr = _readString(item['CreateDate']);
          final createDate =
              createDateStr != null ? DateTime.tryParse(createDateStr) : null;
          return ContractDocument(
            itemId: _readString(item['ItemId']) ?? '',
            name: name,
            uploadDate: uploadDate ?? createDate ?? DateTime.now(),
            fileStorageId: _readString(item['FileStorageId']),
          );
        })
        .where((doc) => doc.itemId.isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> archiveContractDocument({
    required String documentItemId,
  }) async {
    if (documentItemId.isEmpty) return false;
    final context = await _getAuthorizedPersonContext();
    if (context == null) return false;

    final response = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/ArchiveObjectArtifact',
      body: <String, dynamic>{
        'ArchivedFor': ' ',
        'ObjectArtifactId': documentItemId,
        'ArchivedStatus': true,
        'IsArchived': true,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final errors = body['Errors'];
    if (errors is Map) {
      final isValid = errors['IsValid'];
      return isValid == true;
    }
    return statusCode >= 200 && statusCode < 300;
  }

  Future<void> createExternalLinkDocument({
    required String contractItemId,
    required String resourceTitle,
    required String urlAddress,
    required String entityName,
    required String personId,
  }) async {
    final authCtx = await _getAuthorizedPersonContext();
    if (authCtx == null) throw StateError('No authorized context');

    final workspaceId = await _fetchOrCreateWorkspaceId(
      authCtx.userId,
      authCtx.accessToken,
    );

    final objectArtifactId = _newGuid();

    final dmsResponse = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/UploadFile',
      body: <String, dynamic>{
        'ParentId': null,
        'ObjectArtifactId': objectArtifactId,
        'FileStorageId': 'b5e8549a-52d6-4ee5-a7d9-4c27a9d2e7e3',
        'Tags': <String>['portal-url'],
        'FileName': 'link.url',
        'WorkspaceId': workspaceId,
        'GenerateThumbnail': false,
        'MetaData': <String, dynamic>{
          'DocumentSize': <String, dynamic>{
            'Type': 'String',
            'Value': '0',
          },
          'ExternalDocumentCreateDate': <String, dynamic>{
            'Type': 'String',
            'Value': DateTime.now().toIso8601String(),
          },
          'FileType': <String, dynamic>{
            'Type': 'String',
            'Value': 'url',
          },
          'RelatedTo': <String, dynamic>{
            'Type': 'String',
            'Value': 'Drive',
          },
          'Source': <String, dynamic>{
            'Type': 'String',
            'Value': 'Filip',
          },
          'SourceEntityName': <String, dynamic>{
            'Type': 'String',
            'Value': entityName,
          },
          'SourceId': <String, dynamic>{
            'Type': 'String',
            'Value': contractItemId,
          },
          'DocumentId': <String, dynamic>{
            'Type': 'String',
            'Value': resourceTitle,
          },
          'Url': <String, dynamic>{
            'Type': 'String',
            'Value': urlAddress,
          },
        },
      },
      headers: _authorizedHeaders(authCtx.accessToken),
    );

    final dmsStatus = dmsResponse['statusCode'] as int? ?? 0;
    if (dmsStatus < 200 || dmsStatus >= 300) {
      throw StateError(
          'Failed to create external link document (status $dmsStatus)');
    }

    _apiClient
        .postJson(
          url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Insert',
          body: <String, dynamic>{
            'EntityName': 'SnActivityLog',
            'JsonString': jsonEncode(<String, dynamic>{
              'ItemId': _newGuid(),
              'Tags': <String>['Is-A-FilipUpdate', 'portal-url'],
              'Language': 'en-US',
              'ActionType': 'Insert',
              'ActivityEntityName': 'ObjectArtifact',
              'ActivityEntityId': objectArtifactId,
              'ActivityTitle': resourceTitle,
              'OrganizerPersonId': personId,
              'ActivitySource': 'MANUAL',
              'IsLatest': true,
            }),
            'EventData': null,
          },
          headers: _authorizedHeaders(authCtx.accessToken),
        )
        .ignore();
  }

  Future<String> _fetchOrCreateWorkspaceId(
    String ownerUserId,
    String accessToken,
  ) async {
    final queryText =
        'Select <ItemId,StorageAreaId>from<Workspace>where<IsShared=__eql(false) & OwnerId=__eql($ownerUserId)>pageNumber=<0>pageSize=<1>';
    final res = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: <String, dynamic>{
        'EntityName': 'Workspace',
        'Text': queryText,
        'ExcludeCount': true,
      },
      headers: _authorizedHeaders(accessToken),
    );
    final body = res['body'] as Map<String, dynamic>? ?? {};
    final results = body['Results'];
    if (results is List && results.isNotEmpty) {
      final id = _readString((results.first as Map)['ItemId']);
      if (id != null && id.isNotEmpty) return id;
    }

    // No workspace — create one
    final createRes = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/CreateUserWorkspace',
      body: <String, dynamic>{
        'OwnerId': ownerUserId,
        'TotalStorageSpace': 1000,
      },
      headers: _authorizedHeaders(accessToken),
    );
    final createStatus = createRes['statusCode'] as int? ?? 0;
    if (createStatus < 200 || createStatus >= 300) {
      throw StateError('Failed to create workspace (status $createStatus)');
    }

    // Fetch again after creation
    final res2 = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: <String, dynamic>{
        'EntityName': 'Workspace',
        'Text': queryText,
        'ExcludeCount': true,
      },
      headers: _authorizedHeaders(accessToken),
    );
    final body2 = res2['body'] as Map<String, dynamic>? ?? {};
    final results2 = body2['Results'];
    if (results2 is List && results2.isNotEmpty) {
      final id = _readString((results2.first as Map)['ItemId']);
      if (id != null && id.isNotEmpty) return id;
    }
    throw StateError('Workspace not found after creation');
  }

  Future<void> uploadContractDocument({
    required String contractItemId,
    required String resourceTitle,
    required String filePath,
    required String personId,
    required String entityName,
  }) async {
    final authCtx = await _getAuthorizedPersonContext();
    if (authCtx == null) throw StateError('No authorized context');

    final file = File(filePath);
    if (!file.existsSync()) throw StateError('File not found: $filePath');

    final bytes = await file.readAsBytes();
    final fileName = file.uri.pathSegments.last;
    final ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        : '';
    final fileSize = bytes.length;
    final fileSizeStr = fileSize < 1024 * 1024
        ? '${(fileSize / 1024).toStringAsFixed(1)} KB'
        : '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    final fileStorageId = _newGuid();

    final displayName = resourceTitle.isNotEmpty ? resourceTitle : fileName;
    final metaDataJson = jsonEncode(<String, dynamic>{
      'Title': <String, dynamic>{'Type': 'String', 'Value': displayName},
      'OriginalName': <String, dynamic>{'Type': 'String', 'Value': fileName},
    });

    // Step 1: Get presigned upload URL
    final storageResponse = await _apiClient.postJson(
      url: '${_apiClient.storageServiceUrl}StorageQuery/GetPreSignedUrlForUpload',
      body: <String, dynamic>{
        'ItemId': fileStorageId,
        'Name': fileName,
        'MetaData': metaDataJson,
        'ParentDirectoryId': null,
        'Tags': jsonEncode(<String>['UploadFile']),
      },
      headers: _authorizedHeaders(authCtx.accessToken),
    );

    final storageStatus = storageResponse['statusCode'] as int? ?? 0;
    if (storageStatus < 200 || storageStatus >= 300) {
      throw StateError('Failed to get presigned URL (status $storageStatus)');
    }

    final storageBody = storageResponse['body'] as Map<String, dynamic>? ?? {};
    final uploadUrl = storageBody['UploadUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw StateError('No upload URL returned from storage service');
    }

    // Step 2: Upload bytes to presigned URL
    final putStatus = await _apiClient.putBytes(
      url: uploadUrl,
      bytes: bytes,
      extraHeaders: <String, String>{'x-ms-blob-type': 'BlockBlob'},
    );
    if (putStatus < 200 || putStatus >= 300) {
      throw StateError('Failed to upload file to storage (status $putStatus)');
    }

    // Step 3: Register file in DMS
    final workspaceId = await _fetchOrCreateWorkspaceId(
      authCtx.userId,
      authCtx.accessToken,
    );
    final objectArtifactId = _newGuid();
    final dmsResponse = await _apiClient.postJson(
      url: '${_apiClient.dmsServiceUrl}DmsCommand/UploadFile',
      body: <String, dynamic>{
        'ParentId': null,
        'ObjectArtifactId': objectArtifactId,
        'FileStorageId': fileStorageId,
        'Tags': <String>['UploadFile'],
        'FileName': displayName,
        'WorkspaceId': workspaceId,
        'GenerateThumbnail': ext == 'pdf',
        'MetaData': <String, dynamic>{
          'DocumentSize': <String, dynamic>{
            'Type': 'String',
            'Value': fileSizeStr,
          },
          'ExternalDocumentCreateDate': <String, dynamic>{
            'Type': 'String',
            'Value': DateTime.now().toIso8601String(),
          },
          'FileType': <String, dynamic>{
            'Type': 'String',
            'Value': ext,
          },
          'RelatedTo': <String, dynamic>{
            'Type': 'String',
            'Value': 'Drive',
          },
          'Source': <String, dynamic>{
            'Type': 'String',
            'Value': 'Filip',
          },
          'SourceEntityName': <String, dynamic>{
            'Type': 'String',
            'Value': entityName,
          },
          'SourceId': <String, dynamic>{
            'Type': 'String',
            'Value': contractItemId,
          },
          'DocumentId': <String, dynamic>{
            'Type': 'String',
            'Value': displayName,
          },
        },
      },
      headers: _authorizedHeaders(authCtx.accessToken),
    );

    final dmsStatus = dmsResponse['statusCode'] as int? ?? 0;
    if (dmsStatus < 200 || dmsStatus >= 300) {
      throw StateError('Failed to register document in DMS (status $dmsStatus)');
    }

    // Step 4: Insert SnActivityLog (fire-and-forget — do not fail upload if this errors)
    final activityJsonString = jsonEncode(<String, dynamic>{
      'ItemId': _newGuid(),
      'Tags': <String>['Is-A-FilipUpdate', 'upload-file'],
      'Language': 'en-US',
      'ActionType': 'Insert',
      'ActivityEntityName': 'ObjectArtifact',
      'ActivityEntityId': objectArtifactId,
      'ActivityTitle': displayName,
      'OrganizerPersonId': personId,
      'ActivitySource': 'MANUAL',
      'IsLatest': true,
    });

    _apiClient
        .postJson(
          url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Insert',
          body: <String, dynamic>{
            'EntityName': 'SnActivityLog',
            'JsonString': activityJsonString,
            'EventData': null,
          },
          headers: _authorizedHeaders(authCtx.accessToken),
        )
        .ignore();
  }

  Future<List<ContractsLookupOption>> fetchContractTypes(
    String entityName,
  ) async {
    final cached = _contractTypesCache[entityName];
    if (cached != null) {
      return cached;
    }

    final context = await _getAuthorizedPersonContext();
    if (context == null) return const <ContractsLookupOption>[];

    final categoryParent = _contractCategoryParent(entityName);
    if (categoryParent == null) return const <ContractsLookupOption>[];

    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: <String, dynamic>{
        'EntityName': 'Category',
        'Text':
            'Select <ItemId,Child,ChildLabel,Parent>from<Category>where<Parent=__eql($categoryParent)>pageNumber=<0>pageSize=<100>',
        'ExcludeCount': true,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to load contract types.');
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final results = body['Results'];
    if (results is! List) return const <ContractsLookupOption>[];

    final seenValues = <String>{};
    final options = <ContractsLookupOption>[];

    for (final item in results.whereType<Map>()) {
      final value = _readString(item['Child'])?.trim();
      final childLabel = _readString(item['ChildLabel'])?.trim();
      final label = childLabel != null && childLabel.isNotEmpty
          ? childLabel
          : value;
      if (value == null || value.isEmpty || label == null || label.isEmpty) {
        continue;
      }
      if (seenValues.add(value)) {
        options.add(ContractsLookupOption(label: label, value: value));
      }
    }

    _contractTypesCache[entityName] = options;
    return options;
  }

  Future<List<ContractsPartnerOption>> fetchPartners({
    String? searchText,
  }) async {
    final trimmedSearch = searchText?.trim();
    if (trimmedSearch == null || trimmedSearch.isEmpty) {
      final cached = _partnersCache;
      if (cached != null) {
        return cached;
      }
    }

    final context = await _getAuthorizedPersonContext();
    if (context == null) return const <ContractsPartnerOption>[];

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}SelectNetworkQuery/GetPartners',
      body: <String, dynamic>{
        'Labels': null,
        if (trimmedSearch != null && trimmedSearch.isNotEmpty)
          'SearchText': trimmedSearch,
        'Pagination': <String, dynamic>{'PageNumber': 0, 'PageSize': 500},
        'WithCount': false,
        'IsAll': true,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to load partners.');
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    final partners = data is Map<String, dynamic> ? data['Partners'] : null;
    if (partners is! List) return const <ContractsPartnerOption>[];

    final mapped = partners
        .whereType<Map>()
        .map(
          (item) => ContractsPartnerOption(
            itemId: _readString(item['ItemId']) ?? '',
            name: _readString(item['Name']) ?? '',
          ),
        )
        .where((item) => item.itemId.isNotEmpty && item.name.isNotEmpty)
        .toList(growable: false);

    if (trimmedSearch == null || trimmedSearch.isEmpty) {
      _partnersCache = mapped;
    }
    return mapped;
  }

  Future<void> createContract({
    required String contractEntityName,
    required Map<String, dynamic> contractData,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) {
      throw StateError('Missing authorized person context.');
    }

    final payloadData = Map<String, dynamic>.from(contractData)
      ..putIfAbsent('ItemId', _newGuid)
      ..putIfAbsent('PersonId', () => context.personId)
      ..putIfAbsent('Source', () => 'FILIP');
    if (contractEntityName == 'Insure' &&
        !payloadData.containsKey('InsuredPersons')) {
      payloadData['InsuredPersons'] = <String>[context.personId];
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}ContractsCommand/CreateNewContract',
      body: <String, dynamic>{
        'ContractEntityName': contractEntityName,
        'ContractData': payloadData,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to create contract.');
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final errors = body['Errors'];
    final isValid = errors is Map ? errors['IsValid'] == true : false;
    if (!isValid) {
      throw StateError('Failed to create contract.');
    }
  }

  Future<void> updateContract({
    required String contractEntityName,
    required Map<String, dynamic> contractData,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) {
      throw StateError('Missing authorized person context.');
    }

    final payloadData = Map<String, dynamic>.from(contractData)
      ..putIfAbsent('PersonId', () => context.personId)
      ..putIfAbsent('Source', () => 'FILIP');
    if (contractEntityName == 'Insure' &&
        !payloadData.containsKey('InsuredPersons')) {
      payloadData['InsuredPersons'] = <String>[context.personId];
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}ContractsCommand/UpdateContract',
      body: <String, dynamic>{
        'ContractEntityName': contractEntityName,
        'ContractData': payloadData,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to update contract.');
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final errors = body['Errors'];
    final isValid = errors is Map ? errors['IsValid'] == true : false;
    if (!isValid) {
      throw StateError('Failed to update contract.');
    }
  }

  Future<void> updateContractNote({
    required String entityName,
    required String contractItemId,
    required String notes,
    required bool useSyncedUpdate,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || contractItemId.isEmpty) {
      throw StateError('Missing authorized person context.');
    }

    if (useSyncedUpdate) {
      final response = await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}SlSnCommand/CustomUpdate',
        body: <String, dynamic>{
          'EntityName': entityName,
          'ItemId': contractItemId,
          'Properties': <String, dynamic>{'Notes': notes},
          'MessageCorrelationId': _newGuid(),
        },
        headers: _authorizedHeaders(context.accessToken),
      );

      final statusCode = response['statusCode'] as int? ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw StateError('Failed to update contract note.');
      }

      final body =
          response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final errors = body['Errors'];
      final isValid = errors is Map ? errors['IsValid'] == true : true;
      if (!isValid) {
        throw StateError('Failed to update contract note.');
      }
      return;
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Update',
      body: <String, dynamic>{
        'EntityName': entityName,
        'JsonString': jsonEncode(<String, dynamic>{
          'ItemId': contractItemId,
          'Notes': notes,
        }),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to update contract note.');
    }
  }

  Future<void> deleteContract({
    required String contractEntityName,
    required String contractItemId,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || contractItemId.isEmpty) return;

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}ContractsCommand/RemoveContract',
      body: <String, dynamic>{
        'ContractEntityName': contractEntityName,
        'ContractItemId': contractItemId,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to delete contract.');
    }

    final body =
        response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final errors = body['Errors'];
    final isValid = errors is Map ? errors['IsValid'] == true : true;
    if (!isValid) {
      throw StateError('Failed to delete contract.');
    }
  }

  String? _contractCategoryParent(String entityName) {
    switch (entityName) {
      case 'Insure':
        return 'Non - Life Insurance';
      case 'Loan':
        return 'Loan';
      case 'Retirement':
        return 'Life Insurance';
      case 'Investment':
        return 'Investment';
      default:
        return null;
    }
  }

  String? _volatilityToRisk(double? volatility) {
    if (volatility == null) return null;
    if (volatility < 4.7) return 'CONSERVATIVE';
    if (volatility < 6.2) return 'SICHERHEITSORIENTIERT';
    if (volatility < 7.9) return 'BALANCED';
    if (volatility < 9.7) return 'CHANCENORIENTIERT';
    return 'RISIKOFREUDIG';
  }

  Future<_ContractsPersonContext?> _getAuthorizedPersonContext() async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;
    return _ContractsPersonContext(
      accessToken: session.accessToken,
      userId: session.userId,
      personId: session.personId,
      customerId: session.customerId,
      displayName: session.displayName,
    );
  }

  Map<String, String> _authorizedHeaders(String accessToken) =>
      <String, String>{
        'Authorization': 'bearer $accessToken',
        'Origin': _apiClient.originUrl,
      };

  String _newGuid() {
    final random = Random.secure();
    String chunk(int length) {
      const characters = '0123456789abcdef';
      return List<String>.generate(
        length,
        (_) => characters[random.nextInt(characters.length)],
      ).join();
    }

    return '${chunk(8)}-${chunk(4)}-${chunk(4)}-${chunk(4)}-${chunk(12)}';
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

  int _parseColorHex(String? value, {required int fallback}) {
    if (value == null || value.isEmpty) {
      return fallback;
    }

    final normalized = value.replaceFirst('#', '');
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    return int.tryParse(hex, radix: 16) ?? fallback;
  }

  Future<void> _syncCustomerAdditiveContracts({
    required _ContractsPersonContext context,
    required List<String> personIds,
    required bool forceSync,
  }) async {
    final response = await _apiClient.postJson(
      url:
          '${_apiClient.slsnBusinessUrl}ExternalDataSyncCommand/SyncCustomerAdditiveContract',
      body: <String, dynamic>{
        'PersonIds': personIds,
        'CustomerPersonId': context.personId,
        if (forceSync) 'ForceSync': true,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to sync additive investment contracts.');
    }
  }

  List<ContractsHouseholdMember> _mapHouseholdMembers(
    dynamic source, {
    required Set<String> selectedPersonIds,
    required String currentPersonId,
  }) {
    if (source is! List) {
      return const <ContractsHouseholdMember>[];
    }

    return source
        .whereType<Map>()
        .map((item) {
          final displayName = _readString(item['DisplayName']) ?? '';
          final personId = _readString(item['PersonId']) ?? '';
          return ContractsHouseholdMember(
            personId: personId,
            customerId: _readString(item['CustomerId']),
            displayName: displayName,
            avatarColorValue: _parseColorHex(
              _readString(item['ColorCode']),
              fallback: 0xFFD82034,
            ),
            isCurrentUser: personId == currentPersonId,
            profileImageUrl: _apiClient.resolveProfileImageUrl(
              _readString(item['ProfileImage']),
            ),
            email: _readString(item['Email']),
            phoneNumber: _readString(item['PhoneNumber']),
            lastName: _readLastName(
              explicitLastName: _readString(item['LastName']),
              displayName: displayName,
            ),
            proposedUserId: _readString(item['ProposedUserId']),
            managerNr: _readString(item['ManagerNr']),
            totalContracts: _readInt(item['TotalContracts']),
            isSelected: selectedPersonIds.contains(personId),
          );
        })
        .where((member) => member.personId.isNotEmpty)
        .toList(growable: false);
  }

  List<ContractsHouseholdMember> _filterBusinessMembers(
    List<ContractsHouseholdMember> businessMembers, {
    required List<ContractsHouseholdMember> householdMembers,
    required String currentPersonId,
  }) {
    final householdIds = householdMembers
        .map((member) => member.personId)
        .toSet();
    return businessMembers
        .where(
          (member) =>
              !householdIds.contains(member.personId) &&
              member.personId != currentPersonId,
        )
        .toList(growable: false);
  }

  String? _readLastName({
    required String? explicitLastName,
    required String displayName,
  }) {
    if (explicitLastName != null && explicitLastName.trim().isNotEmpty) {
      return explicitLastName.trim();
    }

    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return null;
    }
    return parts.last;
  }

  int _investmentTypeIconCodePoint(String? investmentType) {
    switch (investmentType) {
      case 'PORTFOLIO':
      case 'INSTRUMENT':
        return 0xEA15;
      default:
        return 0xEA15;
    }
  }

  int _insureTypeIconCodePoint(String? insureType) {
    switch (insureType) {
      case 'HH':
        return 0xE998;
      case 'EH':
      case 'HH_EH':
        return 0xE956;
      case 'RS':
        return 0xE99D;
      case 'KFZ':
        return 0xE96B;
      case 'SONST':
        return 0xE939;
      case 'BU':
      case 'RLV':
      case 'RENTE':
        return 0xE948;
      case 'UNFALL':
        return 0xE911;
      case 'KRANK':
        return 0xE973;
      case 'PFLEGE':
        return 0xEA2D;
      default:
        return 0xEA32;
    }
  }

  int _retirementTypeIconCodePoint(String? retirementType) {
    switch (retirementType) {
      case 'FLV':
      case 'KLV':
      case 'PZV':
      case 'RENTE':
        return 0xE948;
      default:
        return 0xE948;
    }
  }

  int _loanTypeIconCodePoint(String? loanType) {
    switch (loanType) {
      case 'Consumer Credit':
      case 'Any Purpose':
      case 'Vehicle':
      case 'Leasing':
      case 'Credit Limit':
      case 'Level Payment Mortgage':
      case 'Interest Only':
        return 0xEA05;
      default:
        return 0xEA05;
    }
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => _readString(item))
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<ContractByIdResult?> fetchContractById({
    required String entityName,
    required String itemId,
  }) async {
    if (itemId.isEmpty) return null;
    final ctx = await _getAuthorizedPersonContext();
    if (ctx == null) return null;

    final normalized = _normalizeEntityName(entityName);
    // Retirement uses ContractEntityName 'Insure' in the API (same as NativeScript)
    final apiEntityName = normalized == 'Retirement' ? 'Insure' : normalized;

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContracts',
      body: <String, dynamic>{
        'PersonIds': <String>[ctx.personId],
        'ContractEntityName': apiEntityName,
        'ExcludeCount': true,
        'ItemIds': <String>[itemId],
      },
      headers: _authorizedHeaders(ctx.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    if (data is! Map<String, dynamic>) return null;

    if (normalized == 'Investment') {
      final list = data['Investments'];
      if (list is! List || list.isEmpty) return null;
      final raw = (list.first as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final contract = InvestmentContract(
        itemId: _readString(raw['ItemId']) ?? itemId,
        title: _readString(raw['Title']),
        iconCodePoint: _investmentTypeIconCodePoint(_readString(raw['InvestmentType'])),
        source: _readString(raw['Source']),
        personId: _readString(raw['PersonId']),
        partnerName: _readString(raw['PartnerName']),
        investmentType: _readString(raw['InvestmentType']),
        bookValueDate: _readDateTime(raw['BookValueDate']),
        investmentStartDate: _readDateTime(raw['InvestmentStartDate']),
        investmentBookValue: _readDouble(raw['InvestmentBookValue']),
        investmentCurrentValue: _readDouble(raw['InvestmentCurrentValue']),
        lumpSumInvestment: _readDouble(raw['LumpSumInvestment']),
        accountNumber: _readString(raw['AccountNumber']),
        contractNumber: _readString(raw['ContractNumber']),
        notes: _readString(raw['Notes']),
        lastUpdateDate: _readDateTime(raw['LastUpdateDate']),
        investmentEndDate: _readDateTime(raw['InvestmentEndDate']),
        paymentFrequency: _readString(raw['PaymentFrequency']),
        isTargetSumSavingsPlan: raw['IsTargetSumSavingsPlan'] is bool ? raw['IsTargetSumSavingsPlan'] as bool : null,
        risk: _readDouble(raw['Risk']),
        isin: _readString(raw['ISIN']),
        numberOfShares: _readDouble(raw['NumberofShares']),
        currentShareValue: _readDouble(raw['CurrentShareValue']),
        interestRate: _readDouble(raw['InterestRate']),
        couponRate: _readDouble(raw['CouponRate']),
        couponType: _readString(raw['CouponType']),
        iban: _readString(raw['IBAN']),
        bic: _readString(raw['BIC']),
        currency: _readString(raw['Currency']),
        issuer: _readString(raw['Issuer']),
        isPremiumBenefit: raw['IsPremiumBenefit'] is bool ? raw['IsPremiumBenefit'] as bool : null,
        bondPrice: _readDouble(raw['BondPrice']),
        bondPriceDate: _readDateTime(raw['BondPriceDate']),
        currentValueDate: _readDateTime(raw['CurrentValueDate']),
        syncDisabledProperties: _readStringList(raw['SyncDisabledProperties']),
      );
      return ContractByIdResult(
        investment: contract,
        insure: null,
        entityName: normalized,
        personId: _readString(raw['PersonId']) ?? ctx.personId,
      );
    } else if (normalized == 'Loan') {
      final list = data['Loans'];
      if (list is! List || list.isEmpty) return null;
      final raw = (list.first as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final contract = InsureContract(
        itemId: _readString(raw['ItemId']) ?? itemId,
        title: _readString(raw['Title']),
        type: _readString(raw['Type']),
        iconCodePoint: _loanTypeIconCodePoint(_readString(raw['Type'])),
        endDate: _readDateTime(raw['DateOfReaminingDept']) ?? _readDateTime(raw['StartDate']),
        grossPremium: _readDouble(raw['RemainingAmount']) ?? _readDouble(raw['Amount']),
        source: _readString(raw['Source']),
        personId: _readString(raw['PersonId']),
        partnerName: _readString(raw['PartnerName']),
        insuredPersons: _readStringList(raw['InsuredPersons']),
        contractNumber: _readString(raw['ContractNumber']),
        notes: _readString(raw['Notes']),
        lastUpdateDate: _readDateTime(raw['LastUpdateDate']),
        syncDisabledProperties: _readStringList(raw['SyncDisabledProperties']),
      );
      return ContractByIdResult(
        insure: contract,
        investment: null,
        entityName: normalized,
        personId: _readString(raw['PersonId']) ?? ctx.personId,
      );
    } else {
      // Insure (non-life) and Retirement — both use 'Insure' entity in the API
      final list = data['Insures'];
      if (list is! List || list.isEmpty) return null;
      final raw = (list.first as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final iconFn = normalized == 'Retirement'
          ? _retirementTypeIconCodePoint
          : _insureTypeIconCodePoint;
      final contract = InsureContract(
        itemId: _readString(raw['ItemId']) ?? itemId,
        title: _readString(raw['Title']),
        type: _readString(raw['Type']),
        iconCodePoint: iconFn(_readString(raw['Type'])),
        endDate: _readDateTime(raw['EndDate']),
        grossPremium: _readDouble(raw['GrossPremium']),
        source: _readString(raw['Source']),
        personId: _readString(raw['PersonId']),
        partnerName: _readString(raw['PartnerName']),
        insuredPersons: _readStringList(raw['InsuredPersons']),
        contractNumber: _readString(raw['ContractNumber']),
        startDate: _readDateTime(raw['StartDate']),
        premiumFrequency: _readString(raw['PremiumFrequency']),
        maturityBenefits: _readDouble(raw['MaturityBenefits']),
        isLifeTime: raw['IsLifeTime'] is bool ? raw['IsLifeTime'] as bool : null,
        status: _readString(raw['Status']),
        adviserVisibility: raw['AdviserVisibility'] is bool ? raw['AdviserVisibility'] as bool : null,
        partnerId: _readString(raw['PartnerId']),
        partnerItemId: _readString(raw['PartnerItemId']),
        productPartnerDescription: _readString(raw['ProductPartnerDescription']),
        notes: _readString(raw['Notes']),
        lastUpdateDate: _readDateTime(raw['LastUpdateDate']),
        vunr: _readString(raw['Vunr']),
        syncDisabledProperties: _readStringList(raw['SyncDisabledProperties']),
        dueDate: _readDateTime(raw['DueDate']),
      );
      return ContractByIdResult(
        insure: contract,
        investment: null,
        entityName: normalized,
        personId: _readString(raw['PersonId']) ?? ctx.personId,
      );
    }
  }

  static String _normalizeEntityName(String entityName) {
    switch (entityName.toLowerCase()) {
      case 'investment':
        return 'Investment';
      case 'retirement':
        return 'Retirement';
      case 'loan':
        return 'Loan';
      default:
        return 'Insure';
    }
  }
}

class ContractByIdResult {
  const ContractByIdResult({
    required this.insure,
    required this.investment,
    required this.entityName,
    required this.personId,
  });

  final InsureContract? insure;
  final InvestmentContract? investment;
  final String entityName;
  final String personId;
}

class _ContractsPersonContext {
  const _ContractsPersonContext({
    required this.accessToken,
    required this.userId,
    required this.personId,
    required this.customerId,
    required this.displayName,
  });

  final String accessToken;
  final String userId;
  final String personId;
  final String customerId;
  final String? displayName;
}

