import 'dart:math';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_models.dart';

class DashboardRepository {
  const DashboardRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
  }) : _apiClient = apiClient,
       _sessionCache = userSessionCache;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;

  Future<UserProfile?> fetchUserProfile() async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;
    return UserProfile(
      displayName: session.displayName,
      email: session.email,
      phoneNumber: session.phoneNumber,
      avatarColorValue: session.avatarColorValue,
      profileImageUrl: session.profileImageUrl,
    );
  }

  Future<DashboardOverviewSummary> fetchOverviewSummary() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) {
      return const DashboardOverviewSummary(
        totalFixedAsset: null,
        totalInvestment: null,
        totalLiabilities: null,
        totalMonthlyPremium: null,
      );
    }

    final assetChartData = await _fetchDashboardAssetChartData(context);
    final totalMonthlyPremium = await _fetchTotalMonthlyPremium(context);

    return DashboardOverviewSummary(
      totalFixedAsset: _readChartTotal(assetChartData, 0),
      totalLiabilities: _readChartTotal(assetChartData, 1),
      totalInvestment: _readChartTotal(assetChartData, 2),
      totalMonthlyPremium: totalMonthlyPremium,
    );
  }

  Future<DashboardInsightsData> fetchInsightsData() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) {
      return DashboardInsightsData(
        distributionCards: const <DashboardDistributionCardData>[],
        advisorInfo: _emptyAdvisorInfo,
      );
    }

    final advisorInfoFuture = _fetchAdvisorInfo(context);
    final investmentCardFuture = _fetchInvestmentDistributionCard(context);
    final monthlyPremiumCardFuture = _fetchMonthlyPremiumDistributionCard(
      context,
    );
    final monthlyPensionCardFuture = _fetchMonthlyPensionDistributionCard(
      context,
    );

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      advisorInfoFuture,
      investmentCardFuture,
      monthlyPremiumCardFuture,
      monthlyPensionCardFuture,
    ]);

    final advisorInfo = results[0] as DashboardAdvisorInfo;
    final investmentCard = results[1] as DashboardDistributionCardData?;
    final monthlyPremiumCard = results[2] as DashboardDistributionCardData;
    final monthlyPensionCard = results[3] as DashboardDistributionCardData;

    final distributionCards = <DashboardDistributionCardData>[
      ?investmentCard,
      monthlyPremiumCard,
      monthlyPensionCard,
    ];

    return DashboardInsightsData(
      distributionCards: distributionCards,
      advisorInfo: advisorInfo,
    );
  }

  Future<void> triggerCalculateAsset() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return;
    try {
      await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}DashboardCommand/CalculateAsset',
        body: <String, dynamic>{
          'PersonIds': <String>[context.personId],
          'NotifyUser': true,
        },
        headers: _authorizedHeaders(context.accessToken),
      );
    } catch (_) {}
  }

  Future<void> triggerSyncCustomerAdditiveContract() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return;
    try {
      await _apiClient.postJson(
        url:
            '${_apiClient.slsnBusinessUrl}ExternalDataSyncCommand/SyncCustomerAdditiveContract',
        body: <String, dynamic>{
          'CustomerPersonId': context.personId,
          'PersonIds': <String>[context.personId],
          'MessageCorrelationId': _newGuid(),
        },
        headers: _authorizedHeaders(context.accessToken),
      );
    } catch (_) {}
  }

  Future<Uri?> fetchDfsInvestmentUri() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null || context.customerId.isEmpty) {
      return null;
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/GetTokenForDfsSso',
      body: <String, dynamic>{
        'pnr': context.customerId,
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load the investment portal link.');
    }

    final responseBody = response['body'] as Map<String, dynamic>;
    final token = _readString(responseBody['Token']);
    if (token == null || token.isEmpty) {
      return null;
    }

    return Uri.parse(_apiClient.dfsBaseUrl)
        .resolve('KvvAuthentication/AuthenticateClient')
        .replace(queryParameters: <String, String>{'jwt': token});
  }

  Future<_AuthorizedPersonContext?> _getAuthorizedPersonContext() async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;
    return _AuthorizedPersonContext(
      accessToken: session.accessToken,
      personId: session.personId,
      customerId: session.customerId,
    );
  }

  Future<List<dynamic>> _fetchDashboardAssetChartData(
    _AuthorizedPersonContext context,
  ) async {
    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}DashboardQuery/GetDashboardAssetChartData',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': <String>[context.personId],
        'MessageCorrelationId': _newGuid(),
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load dashboard asset data.');
    }

    final responseBody = response['body'] as Map<String, dynamic>;
    final rawData = responseBody['Data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : responseBody;
    final chartList = data['AssetChartDatas'];

    if (chartList is List) {
      return chartList;
    }

    return const <dynamic>[];
  }

  Future<double?> _fetchTotalMonthlyPremium(
    _AuthorizedPersonContext context,
  ) async {
    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/GetDistributionChartData',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': <String>[context.personId],
        'ContractEntityName': 'NonLifeInsure&Retirement',
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load monthly premium data.');
    }

    final responseBody = response['body'] as Map<String, dynamic>;
    final chartData = responseBody['ChartData'];
    if (chartData is! List) {
      return 0;
    }

    var total = 0.0;
    for (final item in chartData) {
      if (item is Map) {
        total += _toDouble(item['Amount']) ?? 0;
      }
    }

    return total;
  }

  Future<DashboardDistributionCardData?> _fetchInvestmentDistributionCard(
    _AuthorizedPersonContext context,
  ) async {
    final response = await _fetchDistributionChartData(
      context: context,
      contractEntityName: 'Investment',
    );
    final chartData = _readChartData(response);
    final segments = _mapInvestmentSegments(chartData);

    final totalValue = segments.fold<double>(
      0,
      (previousValue, segment) => previousValue + segment.value,
    );

    return DashboardDistributionCardData(
      cardTitle: 'dashboard.totalInvestment',
      chartTitle: 'dashboard.currentInvestmentDistribution',
      totalValue: totalValue,
      totalValueColorValue: 0xFF15847B,
      chartBackgroundColorValue: 0xFFE3F0EF,
      iconCodePoint: 0xEA15,
      segments: segments,
    );
  }

  Future<DashboardDistributionCardData> _fetchMonthlyPremiumDistributionCard(
    _AuthorizedPersonContext context,
  ) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchContractOverview(
        context: context,
        tags: const <String>['IsANonLifeInsure'],
      ),
      _fetchDistributionChartData(
        context: context,
        contractEntityName: 'Insure',
      ),
    ]);

    final totalValue = _readMonthlyPremiumFromOverview(results[0]) ?? 0;
    final chartData = _readChartData(results[1]);

    return DashboardDistributionCardData(
      cardTitle: 'dashboard.monthlyPremium',
      chartTitle: 'dashboard.monthlyPremiumDistribution',
      totalValue: totalValue,
      totalValueColorValue: 0xFFB4495E,
      chartBackgroundColorValue: 0xFFFFF5F6,
      iconCodePoint: 0xE956,
      segments: _mapTopFiveSegments(chartData, const <int>[
        0xFFA11C36,
        0xFFC77786,
        0xFFD9A4AF,
        0xFF666666,
        0xFFB4B4B4,
        0xFFD2D2D2,
      ]),
    );
  }

  Future<DashboardDistributionCardData> _fetchMonthlyPensionDistributionCard(
    _AuthorizedPersonContext context,
  ) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchContractOverview(
        context: context,
        tags: const <String>['IsALifeInsure'],
      ),
      _fetchDistributionChartData(
        context: context,
        contractEntityName: 'Retirement',
      ),
    ]);

    final totalValue = _readMonthlyPremiumFromOverview(results[0]) ?? 0;
    final chartData = _readChartData(results[1]);

    return DashboardDistributionCardData(
      cardTitle: 'dashboard.monthlyPayment',
      chartTitle: 'dashboard.monthlyPensionDistribution',
      totalValue: totalValue,
      totalValueColorValue: 0xFF607E46,
      chartBackgroundColorValue: 0xFFECF0E9,
      iconCodePoint: 0xE948,
      segments: _mapTopFiveSegments(chartData, const <int>[
        0xFF607E46,
        0xFF90A57E,
        0xFFB0BFA3,
        0xFF666666,
        0xFFB4B4B4,
        0xFFD2D2D2,
      ]),
    );
  }

  Future<Map<String, dynamic>> _fetchDistributionChartData({
    required _AuthorizedPersonContext context,
    required String contractEntityName,
  }) async {
    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/GetDistributionChartData',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': <String>[context.personId],
        'ContractEntityName': contractEntityName,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load distribution chart data.');
    }

    return response['body'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchContractOverview({
    required _AuthorizedPersonContext context,
    required List<String> tags,
  }) async {
    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}ContractsQuery/GetContractOverview',
      body: <String, dynamic>{
        'CustomerPersonId': context.personId,
        'PersonIds': <String>[context.personId],
        'ContractEntityName': 'Insure',
        'ExcludeMonthlyChartData': true,
        'Tags': tags,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load contract overview data.');
    }

    return response['body'] as Map<String, dynamic>;
  }

  Future<DashboardAdvisorInfo> _fetchAdvisorInfo(
    _AuthorizedPersonContext context,
  ) async {
    final advisorPersonId = await _resolveAdvisorPersonId(context);
    if (advisorPersonId == null || advisorPersonId.isEmpty) {
      return _emptyAdvisorInfo;
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: <String, dynamic>{
        'EntityName': 'AdvisorDenormalized',
        'Text':
            'select<ItemId,PersonId,Phone,ProposedUserId,DisplayName,Email,ProfileImageId,ColorCode,ManagerNr> from<AdvisorDenormalized> where<PersonId = __eql($advisorPersonId)>',
        'ExcludeCount': true,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load advisor data.');
    }

    final responseBody = response['body'] as Map<String, dynamic>;
    final results = responseBody['Results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return _emptyAdvisorInfo;
    }

    final advisorData = Map<String, dynamic>.from(results.first as Map);
    return DashboardAdvisorInfo(
      isAvailable: true,
      displayName: _readString(advisorData['DisplayName']),
      email: _readString(advisorData['Email']),
      phone: _readString(advisorData['Phone']),
      profileImageUrl: _apiClient.resolveProfileImageUrl(
        _readString(advisorData['ProfileImageId']),
      ),
      avatarColorValue: _parseColorHex(
        _readString(advisorData['ColorCode']),
        fallback: 0xFF43B883,
      ),
    );
  }

  Future<String?> _resolveAdvisorPersonId(
    _AuthorizedPersonContext context,
  ) async {
    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetConnections',
      body: <String, dynamic>{
        'EntityName': 'Connection',
        'DataFilters': <Map<String, dynamic>>[
          <String, dynamic>{
            'PropertyName': 'ParentEntityName',
            'Value': 'Person',
          },
          <String, dynamic>{
            'PropertyName': 'ChildEntityName',
            'Value': 'Person',
          },
          <String, dynamic>{
            'PropertyName': 'ChildEntityID',
            'Value': context.personId,
          },
          <String, dynamic>{
            'PropertyName': 'Tags',
            'Value': 'Customer-Of-Advisor',
          },
        ],
        'ExpandParent': false,
        'ExpandChild': false,
        'Fields': null,
        'IncludeConnection': false,
        'PageNumber': 0,
        'PageLimit': 100,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception('Unable to load advisor connection data.');
    }

    final responseBody = response['body'] as Map<String, dynamic>;
    final results = responseBody['Results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return null;
    }

    final firstResult = Map<String, dynamic>.from(results.first as Map);
    return _readString(firstResult['ParentEntityID']);
  }

  Map<String, String> _authorizedHeaders(String accessToken) {
    return <String, String>{
      'Authorization': 'bearer $accessToken',
      'Origin': _apiClient.originUrl,
    };
  }

  double? _readChartTotal(List<dynamic> chartData, int index) {
    if (chartData.length <= index) {
      return null;
    }

    final item = chartData[index];
    if (item is! Map) {
      return null;
    }

    return _toDouble(item['Total']);
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }

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

  List<dynamic> _readChartData(dynamic responseBody) {
    if (responseBody is! Map<String, dynamic>) {
      return const <dynamic>[];
    }

    final chartData = responseBody['ChartData'];
    if (chartData is List) {
      return chartData;
    }

    return const <dynamic>[];
  }

  List<DashboardDistributionSegment> _mapInvestmentSegments(
    List<dynamic> chartData,
  ) {
    const colorValues = <int>[
      0xFF15847B,
      0xFF5BA9A3,
      0xFF8AC2BD,
      0xFF666666,
      0xFFB4B4B4,
      0xFFD2D2D2,
    ];

    // NativeScript includes ALL items (even zero/negative) so the list view
    // and total match the server data exactly. Negatives are clipped to 0 only
    // when drawing the donut arc (handled in _DonutChartPainter).
    final hasAnyPositive = chartData.any((item) {
      if (item is! Map) return false;
      return (_toDouble(item['Amount']) ?? 0) > 0;
    });
    if (!hasAnyPositive) return const <DashboardDistributionSegment>[];

    final segments = <DashboardDistributionSegment>[];
    for (var index = 0; index < chartData.length; index++) {
      final item = chartData[index];
      if (item is! Map) continue;
      final amount = _toDouble(item['Amount']) ?? 0;
      segments.add(
        DashboardDistributionSegment(
          label: _readString(item['Name']) ?? '-',
          value: amount,
          colorValue: colorValues[index % colorValues.length],
        ),
      );
    }
    return segments;
  }

  List<DashboardDistributionSegment> _mapTopFiveSegments(
    List<dynamic> chartData,
    List<int> colorValues,
  ) {
    final validItems = chartData
        .whereType<Map>()
        .map((item) {
          return <String, dynamic>{
            'Name': _readString(item['Name']) ?? '-',
            'Amount': _toDouble(item['Amount']) ?? 0,
          };
        })
        .where((item) => (item['Amount'] as double) > 0)
        .toList();

    if (validItems.isEmpty) {
      return const <DashboardDistributionSegment>[];
    }

    final segments = <DashboardDistributionSegment>[];
    final visibleItems = validItems.take(5).toList();

    for (var index = 0; index < visibleItems.length; index++) {
      final item = visibleItems[index];
      segments.add(
        DashboardDistributionSegment(
          label: item['Name'] as String,
          value: item['Amount'] as double,
          colorValue: colorValues[index % colorValues.length],
        ),
      );
    }

    if (validItems.length > 5) {
      final totalAmount = validItems.fold<double>(
        0,
        (sum, item) => sum + (item['Amount'] as double),
      );
      final firstFiveAmount = visibleItems.fold<double>(
        0,
        (sum, item) => sum + (item['Amount'] as double),
      );
      final remainingAmount = totalAmount - firstFiveAmount;

      if (remainingAmount > 0) {
        segments.add(
          DashboardDistributionSegment(
            label: 'dashboard.otherCategories',
            value: remainingAmount,
            colorValue: colorValues.length > 5 ? colorValues[5] : 0xFFD2D2D2,
          ),
        );
      }
    }

    return segments;
  }

  double? _readMonthlyPremiumFromOverview(Map<String, dynamic> responseBody) {
    final data = responseBody['Data'];
    if (data is! Map) {
      return 0;
    }

    final overview = data['Overview'];
    if (overview is! Map) {
      return 0;
    }

    return _toDouble(overview['MonthlyPremium']) ?? 0;
  }

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  int _parseColorHex(String? value, {required int fallback}) {
    if (value == null || value.isEmpty) {
      return fallback;
    }

    final normalized = value.replaceFirst('#', '');
    if (normalized.length == 6) {
      return int.tryParse('0xFF$normalized') ?? fallback;
    }
    if (normalized.length == 8) {
      return int.tryParse('0x$normalized') ?? fallback;
    }
    return fallback;
  }
}

class _AuthorizedPersonContext {
  const _AuthorizedPersonContext({
    required this.accessToken,
    required this.personId,
    required this.customerId,
  });

  final String accessToken;
  final String personId;
  final String customerId;
}

const DashboardAdvisorInfo _emptyAdvisorInfo = DashboardAdvisorInfo(
  isAvailable: false,
  displayName: null,
  email: null,
  phone: null,
  profileImageUrl: null,
  avatarColorValue: 0xFF43B883,
);
