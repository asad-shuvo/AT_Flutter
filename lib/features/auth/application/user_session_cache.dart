import 'dart:convert';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';

/// Cached user identity resolved once per session after login.
/// Combines the Person record query (personId, customerId) and the profile
/// query (DisplayName, Email, PhoneNumber, ColorCode) into a single API call.
/// Call [invalidate] on logout so the next login gets fresh data.
class UserSessionData {
  const UserSessionData({
    required this.accessToken,
    required this.userId,
    required this.personId,
    required this.customerId,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.avatarColorValue,
    required this.profileImageUrl,
  });

  final String accessToken;
  final String userId;
  final String personId;
  final String customerId;
  final String displayName;
  final String email;
  final String phoneNumber;
  final int avatarColorValue;
  final String? profileImageUrl;
}

class UserSessionCache {
  UserSessionCache({
    required ApiClient apiClient,
    required SecureStorageService secureStorageService,
  })  : _apiClient = apiClient,
        _secureStorageService = secureStorageService;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorageService;

  UserSessionData? _cached;
  Future<UserSessionData?>? _pending;

  /// Returns cached session data, fetching from API on first call.
  /// Concurrent callers share a single in-flight request.
  Future<UserSessionData?> resolve() {
    if (_cached != null) return Future.value(_cached);
    return _pending ??= _fetch().then((data) {
      _cached = data;
      return data;
    });
  }

  /// Clears cached data. Call on logout so the next login fetches fresh data.
  void invalidate() {
    _cached = null;
    _pending = null;
  }

  Future<UserSessionData?> _fetch() async {
    final accessToken = await _secureStorageService.read(
      AppStorageKeys.accessToken,
    );
    if (accessToken == null || accessToken.isEmpty) return null;

    final userId = _extractUserId(accessToken);
    if (userId == null || userId.isEmpty) return null;

    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: <String, dynamic>{
        'EntityName': 'Person',
        'Text':
            'Select <ItemId,CustomerId,DisplayName,Email,PhoneNumber,ColorCode,ProfileImage,ProfileImageId>from<Person>where<ProposedUserId=__eql($userId)>pageNumber=<0>pageSize=<1>',
        'ExcludeCount': true,
      },
      headers: <String, String>{
        'Authorization': 'bearer $accessToken',
        'Origin': _apiClient.originUrl,
      },
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final responseBody = response['body'] as Map<String, dynamic>;
    final results = responseBody['Results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return null;
    }

    final data = Map<String, dynamic>.from(results.first as Map);
    final personId = _readString(data['ItemId']) ?? '';
    if (personId.isEmpty) return null;
    final customerId = _readString(data['CustomerId']) ?? '';

    await _secureStorageService.write(
      key: AppStorageKeys.userId,
      value: userId,
    );
    if (customerId.isNotEmpty) {
      await _secureStorageService.write(
        key: AppStorageKeys.customerId,
        value: customerId,
      );
    }

    return UserSessionData(
      accessToken: accessToken,
      userId: userId,
      personId: personId,
      customerId: customerId,
      displayName: _readString(data['DisplayName']) ?? '',
      email: _readString(data['Email']) ?? '',
      phoneNumber: _readString(data['PhoneNumber']) ?? '-',
      avatarColorValue: _parseColorHex(
        _readString(data['ColorCode']),
        fallback: 0xFF3BAF8E,
      ),
      profileImageUrl: _apiClient.resolveProfileImageUrl(
        _readString(data['ProfileImage']) ?? _readString(data['ProfileImageId']),
      ),
    );
  }

  String? _extractUserId(String accessToken) {
    final segments = accessToken.split('.');
    if (segments.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final userId = decoded['user_id'];
      return userId is String ? userId : userId?.toString();
    } catch (_) {
      return null;
    }
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  int _parseColorHex(String? value, {required int fallback}) {
    if (value == null || value.isEmpty) return fallback;
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
