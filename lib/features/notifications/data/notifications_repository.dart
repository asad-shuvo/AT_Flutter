import 'dart:convert';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:filip_at_flutter/features/notifications/data/notification_item_model.dart';

class NotificationsRepository {
  const NotificationsRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorageService,
  })  : _apiClient = apiClient,
        _secureStorageService = secureStorageService;

  static const List<String> _responseKeys = <String>[
    'contractadded',
    'newsignaturedocumentuploaded',
    'SchedulingNotification',
    'Mobile_App_Push_Notification',
  ];

  final ApiClient _apiClient;
  final SecureStorageService _secureStorageService;

  Future<NotificationsData> fetchNotifications({
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) {
      return const NotificationsData(items: <NotificationItem>[], totalCount: 0, hasMore: false);
    }

    final response = await _apiClient.postJson(
      url: '${_apiClient.notificationUrl}/api/Notifier/GetOfflineNotificationsByQuery',
      body: <String, dynamic>{
        'OrderByCreatedDate': 1,
        'ReturnCount': true,
        'ResponseKeyFilterOperator': 'In',
        'ResponseKeys': _responseKeys,
        'PageNumber': pageNumber,
        'PageSize': pageSize,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to fetch notifications.');
    }

    final body = response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = body['Data'];
    final list = data is List ? data : const <dynamic>[];
    final totalCount = _readInt(body['TotalCount']) ?? list.length;

    final items = list
        .whereType<Map>()
        .map((raw) => _mapNotification(raw.cast<String, dynamic>()))
        .whereType<NotificationItem>()
        .toList(growable: false);

    return NotificationsData(
      items: items,
      totalCount: totalCount,
      hasMore: items.length >= pageSize,
    );
  }

  Future<int> fetchUnreadCount() async {
    final context = await _getAuthorizedPersonContext();
    if (context == null) return 0;

    final response = await _apiClient.postJson(
      url: '${_apiClient.notificationUrl}/api/Notifier/GetOfflineNotificationsByQuery',
      body: <String, dynamic>{
        'OrderByCreatedDate': 1,
        'ReturnCount': true,
        'ResponseKeyFilterOperator': 'In',
        'ResponseKeys': _responseKeys,
        'OnlyUnread': true,
        'PageNumber': 1,
        'PageSize': 1,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return 0;
    final body = response['body'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return _readInt(body['TotalCount']) ?? 0;
  }

  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    final context = await _getAuthorizedPersonContext();
    if (context == null || context.userId.isEmpty) return;

    final response = await _apiClient.postJson(
      url: '${_apiClient.notificationUrl}/api/Notifier/UpdateNotificationStatusToRead',
      body: <String, dynamic>{
        'UserId': context.userId,
        'NotificationIds': notificationIds,
      },
      headers: _authorizedHeaders(context.accessToken),
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw StateError('Failed to update notification read status.');
    }
  }

  NotificationItem? _mapNotification(Map<String, dynamic> raw) {
    final payload = raw['Payload'];
    if (payload is! Map) return null;

    final responseKey = _readString(payload['ResponseKey']) ?? '';
    if (!_responseKeys.contains(responseKey)) return null;

    final denormalized = _parseDenormalizedPayload(raw['DenormalizedPayload']);
    final message = denormalized['message'];
    final messageMap = message is Map ? message.cast<String, dynamic>() : const <String, dynamic>{};
    final denormalizedKey = _readString(denormalized['key']) ?? '';

    final textData = _buildTextData(
      responseKey: responseKey,
      message: messageMap,
      denormalizedKey: denormalizedKey,
    );
    if (textData == null) return null;

    final createdTime = DateTime.tryParse(_readString(raw['CreatedTime']) ?? '')?.toLocal();
    if (createdTime == null) return null;

    return NotificationItem(
      id: _readString(raw['Id']) ?? '',
      responseKey: responseKey,
      titleKey: textData.titleKey,
      subtitleKey: textData.subtitleKey,
      subtitleName: textData.subtitleName,
      subtitleDate: textData.subtitleDate,
      iconCodePoint: _notificationIconCodePoint(responseKey),
      createdTime: createdTime,
      isRead: raw['IsRead'] == true,
      payload: denormalized,
    );
  }

  _NotificationTextData? _buildTextData({
    required String responseKey,
    required Map<String, dynamic> message,
    required String denormalizedKey,
  }) {
    switch (responseKey) {
      case 'contractadded':
        return _NotificationTextData(
          titleKey: 'CONTRACT_ADDED',
          subtitleKey: 'tns.contractsAddedNotificationSubtitle',
          subtitleName: _readString(message['Title']),
        );
      case 'newsignaturedocumentuploaded':
        return _NotificationTextData(
          titleKey: 'NEW_SIGNATURE_DOCUMENT_UPLOADED',
          subtitleKey: 'tns.esignNotificationSubtitle',
          subtitleName: _readString(message['ContractTitle']),
        );
      case 'SchedulingNotification':
        if (denormalizedKey == 'EXPIRINGCONTRACT_CUSTOMER') {
          final expiryDate = DateTime.tryParse(_readString(message['ExpiryDateOfTheContract']) ?? '');
          return _NotificationTextData(
            titleKey: 'CONTRACT_UPDATE',
            subtitleKey: 'tns.contractsUpdateNotificationSubtitle',
            subtitleName: _readString(message['Title']),
            subtitleDate: expiryDate?.toLocal(),
          );
        }
        return null;
      case 'Mobile_App_Push_Notification':
        return const _NotificationTextData(
          titleKey: 'SLS_INVESTMENT_NOTIFICATION_TITLE',
          subtitleKey: 'SLS_INVESTMENT_NOTIFICATION_SUB_TITLE',
        );
      default:
        return null;
    }
  }

  int _notificationIconCodePoint(String responseKey) {
    switch (responseKey) {
      case 'newsignaturedocumentuploaded':
        return 0xE9D3;
      case 'Mobile_App_Push_Notification':
        return 0xEA16;
      case 'contractadded':
      case 'SchedulingNotification':
      default:
        return 0xE9BE;
    }
  }

  Map<String, dynamic> _parseDenormalizedPayload(dynamic source) {
    if (source is Map<String, dynamic>) return source;
    if (source is! String || source.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<_NotificationsPersonContext?> _getAuthorizedPersonContext() async {
    final accessToken = await _secureStorageService.read(AppStorageKeys.accessToken);
    if (accessToken == null || accessToken.isEmpty) return null;

    final userId = _extractUserId(accessToken);
    if (userId == null || userId.isEmpty) return null;

    return _NotificationsPersonContext(accessToken: accessToken, userId: userId);
  }

  Map<String, String> _authorizedHeaders(String accessToken) => <String, String>{
        'Authorization': 'bearer $accessToken',
        'Origin': _apiClient.originUrl,
      };

  String? _extractUserId(String accessToken) {
    final segments = accessToken.split('.');
    if (segments.length < 2) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(segments[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final userId = decoded['user_id'];
      return userId is String ? userId : userId?.toString();
    } catch (_) {
      return null;
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _readString(dynamic value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return null;
  }

}

class _NotificationsPersonContext {
  const _NotificationsPersonContext({
    required this.accessToken,
    required this.userId,
  });

  final String accessToken;
  final String userId;
}

class _NotificationTextData {
  const _NotificationTextData({
    required this.titleKey,
    required this.subtitleKey,
    this.subtitleName,
    this.subtitleDate,
  });

  final String titleKey;
  final String subtitleKey;
  final String? subtitleName;
  final DateTime? subtitleDate;
}
