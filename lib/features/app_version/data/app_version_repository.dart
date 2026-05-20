import 'dart:convert';
import 'dart:io';

import 'package:filip_at_flutter/core/network/api_client.dart';

enum AppVersionStatus { ok, maintenance, forceUpdate }

class AppVersionRepository {
  const AppVersionRepository({
    required ApiClient apiClient,
    required String appVersion,
  })  : _apiClient = apiClient,
        _appVersion = appVersion;

  final ApiClient _apiClient;
  final String _appVersion;

  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=ch.selise.sln.at';
  static const String _iosStoreUrl =
      'https://apps.apple.com/us/app/id1635035282';

  String get storeUrl => Platform.isAndroid ? _androidStoreUrl : _iosStoreUrl;

  Future<AppVersionStatus> checkAppVersion(String accessToken) async {
    try {
      const query =
          'Select <Name,Key,Value>from<PlatformDictionary>where<Key=__eql(APP_VERSION)>pageNumber=<0>pageSize= <100>';
      final response = await _apiClient.postJson(
        url:
            '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
        body: <String, dynamic>{
          'EntityName': 'PlatformDictionary',
          'Text': query,
        },
        headers: <String, String>{
          'Authorization': 'bearer $accessToken',
          'Origin': _apiClient.originUrl,
        },
      );

      final statusCode = response['statusCode'] as int? ?? 0;
      if (statusCode < 200 || statusCode >= 300) return AppVersionStatus.ok;

      final body = response['body'];
      if (body is! Map<String, dynamic>) return AppVersionStatus.ok;
      final results = body['Results'];
      if (results is! List || results.isEmpty) return AppVersionStatus.ok;

      final firstResult = results[0];
      if (firstResult is! Map<String, dynamic>) return AppVersionStatus.ok;
      final valueStr = firstResult['Value'] as String?;
      if (valueStr == null || valueStr.isEmpty) return AppVersionStatus.ok;

      final dynamic decoded = jsonDecode(valueStr);
      if (decoded is! Map<String, dynamic>) return AppVersionStatus.ok;

      final isMaintenance = decoded['isMaintenance'] as bool? ?? false;
      if (isMaintenance) return AppVersionStatus.maintenance;

      final isUpdateMandatory = Platform.isAndroid
          ? decoded['isAndroidUpdateMandatory'] as bool? ?? false
          : decoded['isIosUpdateMandatory'] as bool? ?? false;

      final dbVersion = (Platform.isAndroid
              ? decoded['android'] as String?
              : decoded['ios'] as String?) ??
          '';

      final avoidUpdateVersion = (Platform.isAndroid
              ? decoded['androidAvoidUpdateVersion'] as String?
              : decoded['iosAvoidUpdateVersion'] as String?) ??
          '';

      if (isUpdateMandatory &&
          dbVersion.isNotEmpty &&
          dbVersion != _appVersion &&
          _appVersion != avoidUpdateVersion) {
        return AppVersionStatus.forceUpdate;
      }

      return AppVersionStatus.ok;
    } catch (_) {
      return AppVersionStatus.ok;
    }
  }
}
