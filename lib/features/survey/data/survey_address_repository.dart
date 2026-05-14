import 'dart:convert';
import 'dart:math';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';

class SurveyAddressRepository {
  const SurveyAddressRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
  }) : _apiClient = apiClient,
       _sessionCache = userSessionCache;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;

  Future<List<PostalSuggestion>> fetchPostalSuggestions(
    String code, {
    int pageNumber = 0,
  }) async {
    final context = await _getContext();
    if (context == null) return const <PostalSuggestion>[];

    final response = await _apiClient.postJson(
      url: '${_apiClient.snQueryUrl}SelectNetworkQuery/GetZipCode',
      body: <String, dynamic>{
        'Code': code,
        'Pagination': <String, dynamic>{
          'PageNumber': pageNumber,
          'PageSize': 10,
        },
      },
      headers: _headers(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return const <PostalSuggestion>[];

    final body = response['body'];
    final data = body is Map ? body['Data'] : null;
    final dataList = data is Map ? data['Data'] : (data is List ? data : null);
    if (dataList is! List) return const <PostalSuggestion>[];

    return dataList.whereType<Map>().map((item) {
      final district = _str(item['District']) ?? '';
      final zipCode = _str(item['Code']) ?? '';
      return PostalSuggestion(
        description: '$district $zipCode',
        code: zipCode,
        city: district,
      );
    }).toList();
  }

  Future<List<CountryOption>> fetchCountryList() async {
    final context = await _getContext();
    if (context == null) return const <CountryOption>[];

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/GetKvvDataDictionary',
      body: <String, dynamic>{'Type': 'Country'},
      headers: _headers(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return const <CountryOption>[];

    final body = response['body'];
    final items = body is Map ? body['Items'] : null;
    if (items is! List) return const <CountryOption>[];

    return items.whereType<Map>().map((item) {
      return CountryOption(
        code: _str(item['Key']) ?? '',
        name: _str(item['Value']) ?? '',
      );
    }).toList();
  }

  Future<bool> updatePersonAddress({
    required String itemId,
    required String street,
    required String cityState,
    required String postalCode,
    required String country,
    required String addressLine1,
    required Map<String, dynamic> fullPersonData,
  }) async {
    final context = await _getContext();
    if (context == null) return false;

    final pdsData = <String, dynamic>{
      if (itemId.isNotEmpty) 'ItemId': itemId,
      'Street': street,
      'City': cityState,
      'State': cityState,
      'PostalCode': postalCode,
      'Country': country,
      'AddressLine1': addressLine1,
    };

    final pdsResponse = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationCommand/Update',
      body: <String, dynamic>{
        'EntityName': 'Person',
        'JsonString': jsonEncode(pdsData),
      },
      headers: _headers(context.accessToken),
    );

    final pdsStatus = pdsResponse['statusCode'] as int? ?? 0;
    if (pdsStatus < 200 || pdsStatus >= 300) return false;
    final pdsBody = pdsResponse['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final pdsErrors = pdsBody['Errors'];
    if (pdsErrors is! Map || pdsErrors['IsValid'] != true) return false;

    final kvvData = <String, dynamic>{
      ...fullPersonData,
      'Street': street,
      'City': cityState,
      'State': cityState,
      'PostalCode': postalCode,
      'Country': country,
      'AddressLine1': addressLine1,
      'Currency': '€',
      'MessageCorrelationId': _newGuid(),
    };
    kvvData.removeWhere((_, value) => value == null);

    await _apiClient.postJson(
      url: '${_apiClient.baseUrl}/business-sln-kvv/kvvintegration/KvvIntegrationCommand/UpdateKvvCustomer',
      body: kvvData,
      headers: _headers(context.accessToken),
    );

    return true;
  }

  Future<_Context?> _getContext() async {
    final session = await _sessionCache.resolve();
    if (session == null) return null;
    return _Context(
      accessToken: session.accessToken,
      personId: session.personId,
    );
  }

  Map<String, String> _headers(String token) => <String, String>{
        'Authorization': 'bearer $token',
        'Origin': _apiClient.originUrl,
      };

  String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  String _newGuid() {
    final random = Random.secure();
    String chunk(int length) {
      const chars = '0123456789abcdef';
      return List<String>.generate(
        length,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
    }
    return '${chunk(8)}-${chunk(4)}-${chunk(4)}-${chunk(4)}-${chunk(12)}';
  }
}

class PostalSuggestion {
  const PostalSuggestion({
    required this.description,
    required this.code,
    required this.city,
  });

  final String description;
  final String code;
  final String city;
}

class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

class _Context {
  const _Context({required this.accessToken, required this.personId});
  final String accessToken;
  final String personId;
}
