import 'dart:convert';
import 'dart:io';

import 'package:filip_at_flutter/core/network/api_client.dart';

class LoginSyncRepository {
  const LoginSyncRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> syncCustomerDataById({
    required String accessToken,
    required String customerId,
    required String userId,
    required String userName,
  }) async {
    if (customerId.isEmpty) return;
    try {
      await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}SlSnCommand/SyncCustomerDataById',
        body: <String, dynamic>{
          'CustomerId': customerId,
          'NotifyUserId': userId,
          'NotifyUserName': userName,
          'CallerContext': 'KVV_SYNC',
        },
        headers: <String, String>{
          'Authorization': 'bearer $accessToken',
          'Origin': _apiClient.originUrl,
        },
      );
    } catch (_) {}
  }

  Future<void> syncGdprConsentFromKvv({
    required String accessToken,
    required String customerId,
  }) async {
    if (customerId.isEmpty) return;
    try {
      await _apiClient.postJson(
        url:
            '${_apiClient.slsnBusinessUrl}SlSnCommand/SyncGdprConsentFromKvv',
        body: <String, dynamic>{
          'CustomerId': customerId,
          'IsHouseholdMemberConsentSync': true,
        },
        headers: <String, String>{
          'Authorization': 'bearer $accessToken',
          'Origin': _apiClient.originUrl,
        },
      );
    } catch (_) {}
  }

  Future<void> addLoginPlatform({required String accessToken}) async {
    try {
      final String platform;
      if (Platform.isAndroid) {
        platform = 'ANDROID';
      } else if (Platform.isIOS) {
        platform = 'IOS';
      } else {
        platform = 'OTHER';
      }

      final deviceInfo = jsonEncode(<String, dynamic>{
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
      });

      await _apiClient.postJson(
        url: '${_apiClient.slsnBusinessUrl}SlSnCommand/AddLoginPlatform',
        body: <String, dynamic>{
          'Platform': platform,
          'DeviceInfo': deviceInfo,
        },
        headers: <String, String>{
          'Authorization': 'bearer $accessToken',
          'Origin': _apiClient.originUrl,
        },
      );
    } catch (_) {}
  }
}
