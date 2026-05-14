import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';

class FcmService {
  final SyncNotificationService _syncNotificationService;
  final SecureStorageService _secureStorage;
  late final FirebaseMessaging _messaging;
  GlobalKey<NavigatorState>? _navigatorKey;

  FcmService({
    required SyncNotificationService syncNotificationService,
    required SecureStorageService secureStorage,
  })  : _syncNotificationService = syncNotificationService,
        _secureStorage = secureStorage;

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;
    _logEvent('Firebase initialized');
  }

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> setupMessaging(String investmentPushNotificationKey) async {
    final settings = await _messaging.requestPermission();
    _logEvent('Notification permission status: ${settings.authorizationStatus}');

    await _messaging.subscribeToTopic(investmentPushNotificationKey);
    _logEvent('Subscribed to broadcast topic: $investmentPushNotificationKey');
  }

  Future<void> subscribeToUserTopic(String userId) async {
    final previous = await _secureStorage.read(AppStorageKeys.firebaseTopic);
    if (previous != null && previous.isNotEmpty) {
      try {
        await _messaging.unsubscribeFromTopic(previous);
        _logEvent('Unsubscribed from previous topic: $previous');
      } catch (e) {
        _logEvent('Error unsubscribing from previous topic: $e');
      }
    }

    await _messaging.subscribeToTopic(userId);
    await _secureStorage.write(key: AppStorageKeys.firebaseTopic, value: userId);
    _logEvent('Subscribed to user topic: $userId');
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      await _messaging.unsubscribeFromTopic(userId);
      await _secureStorage.delete(AppStorageKeys.firebaseTopic);
      _logEvent('Unsubscribed from user topic: $userId');
    } catch (e) {
      _logEvent('Error unsubscribing from user topic: $e');
    }
  }

  void startListening() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessage(message, fromTap: true);
    });

    _logEvent('FCM listeners started');
  }

  void _handleRemoteMessage(RemoteMessage message, {bool fromTap = false}) {
    try {
      final notificationData = _extractNotificationData(message.data);
      if (notificationData == null) {
        _logEvent('No parseable notification payload in message: ${message.data}');
        return;
      }

      final notificationKey = _extractNotificationKey(notificationData);
      if (notificationKey == null) {
        _logEvent('No notificationKey found in payload');
        _logEvent('Payload without notificationKey => $notificationData');
        return;
      }

      _logEvent('Received notification: $notificationKey (fromTap: $fromTap)');
      _routeNotificationKey(notificationKey, notificationData, fromTap);
    } catch (e) {
      _logEvent('Error handling remote message: $e');
    }
  }

  void _routeNotificationKey(
    String key,
    Map<String, dynamic> data,
    bool fromTap,
  ) {
    _logGdprNotificationDebug(key, data, fromTap: fromTap);
    if (fromTap) {
      _handleTapNotification(key, data);
    } else {
      _handleDataNotification(key, data);
    }
  }

  void _handleTapNotification(String key, Map<String, dynamic> data) {
    if (_navigatorKey == null) {
      _logEvent('Navigator key not set; cannot navigate');
      return;
    }

    final navigator = _navigatorKey!.currentState;
    if (navigator == null) {
      _logEvent('Navigator not available');
      return;
    }

    switch (key) {
      case 'contractadded':
      case 'SchedulingNotification':
      case 'ContractAnniversary':
        final message = data['message'] as Map<String, dynamic>?;
        if (message != null) {
          final entityName = message['EntityName'];
          final itemId = message['ItemId'];
          navigator.pushNamed(
            '/contract-detail',
            arguments: {'entityName': entityName, 'itemId': itemId},
          );
          _logEvent('Navigated to contract detail: $entityName/$itemId');
        }
        break;
      case 'newsignaturedocumentuploaded':
        navigator.pushNamed('/notifications');
        _logEvent('Navigated to notifications');
        break;
      case 'Mobile_App_Push_Notification':
        final message = data['message'] as Map<String, dynamic>?;
        if (message != null) {
          final url = message['Url'];
          _logEvent('Would launch URL: $url');
        }
        break;
      case 'MessagingThreadNotification':
        navigator.pushNamed('/chat');
        _logEvent('Navigated to chat');
        break;
      case 'FilipAppUpdate':
        navigator.pushNamed('/app-update');
        _logEvent('Navigated to app-update');
        break;
      case 'MeetingRecordAdded':
        navigator.pushNamed('/drive');
        _logEvent('Navigated to drive');
        break;
      case 'AnnouncementBroadCast':
        navigator.pushNamed('/notifications');
        _logEvent('Navigated to notifications for announcement');
        break;
      default:
        _logEvent('Unhandled tap notification: $key');
    }
  }

  void _handleDataNotification(String key, Map<String, dynamic> data) {
    switch (key.toLowerCase()) {
      case 'contract_sync_completed':
      case 'fcczskcontractsync':
        _syncNotificationService.contractSyncCompleted.add(data);
        _logEvent('Emitted to contractSyncCompleted');
        break;
      case 'investment_contracts_sync_completed':
        _syncNotificationService.investmentContractSyncCompleted.add(data);
        _logEvent('Emitted to investmentContractSyncCompleted');
        break;
      case 'assetcalculationcompleted':
        _syncNotificationService.assetCalculationSyncCompleted.add(data);
        _logEvent('Emitted to assetCalculationSyncCompleted');
        break;
      case 'customer_external_contract_sync_completed':
        _syncNotificationService.externalContractSyncCompleted.add(data);
        _logEvent('Emitted to externalContractSyncCompleted');
        break;
      case 'synccustomercontract':
        _syncNotificationService.synccustomercontract.add(data);
        _logEvent('Emitted to synccustomercontract');
        break;
      case 'investmentsync':
        _syncNotificationService.investmentSync.add(data);
        _logEvent('Emitted to investmentSync');
        break;
      case 'portfolio_investment_sync_completed':
        _syncNotificationService.portfolioInvestmentSync.add(data);
        _logEvent('Emitted to portfolioInvestmentSync');
        break;
      case 'portfolio_findata_sync_completed':
        _syncNotificationService.portfolioForceSync.add(data);
        _logEvent('Emitted to portfolioForceSync');
        break;
      case 'synccustomerdatabyid':
        _syncNotificationService.synccustomerdatabyid.add(data);
        _logEvent('Emitted to synccustomerdatabyid');
        break;
      case 'synccustomergdprconsentstatus':
      case 'gdprconsentstatusresponse':
      case 'gdpr_consent_sync':
        _syncNotificationService.gdprConsentSync.add(data);
        _logEvent('Emitted to gdprConsentSync');
        break;
      case 'person_contract_sync_completed':
        _syncNotificationService.personContractSync.add(data);
        _logEvent('Emitted to personContractSync');
        break;
      case 'household_members_contract_sync_completed':
        _syncNotificationService.householdExternalSync.add(data);
        _logEvent('Emitted to householdExternalSync');
        break;
      default:
        _logEvent('Unhandled data notification: $key');
    }
  }

  void _logEvent(String message) {
    // ignore: avoid_print
    print('[FCM] $message');
  }

  String? _extractNotificationKey(Map<String, dynamic> data) {
    final direct =
        data['notificationKey'] ??
        data['NotificationKey'] ??
        data['notificationkey'] ??
        data['responseKey'] ??
        data['ResponseKey'] ??
        data['responsekey'] ??
        data['key'] ??
        data['Key'];
    if (direct is String && direct.isNotEmpty) return direct;

    final message = data['message'];
    if (message is Map) {
      final nested =
          message['notificationKey'] ??
          message['NotificationKey'] ??
          message['notificationkey'] ??
          message['key'] ??
          message['Key'];
      if (nested is String && nested.isNotEmpty) return nested;
    }

    final denormalizedPayload =
        data['DenormalizedPayload'] ?? data['denormalizedPayload'];
    if (denormalizedPayload is String && denormalizedPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(denormalizedPayload);
        if (decoded is Map<String, dynamic>) {
          return _extractNotificationKey(decoded);
        }
      } catch (_) {}
    } else if (denormalizedPayload is Map<String, dynamic>) {
      return _extractNotificationKey(denormalizedPayload);
    }
    return null;
  }

  Map<String, dynamic>? _extractNotificationData(Map<String, dynamic> rawData) {
    if (rawData.isEmpty) return null;

    final directPayload =
        rawData['DenormalizedPayload'] ?? rawData['denormalizedPayload'];
    if (directPayload is String && directPayload.isNotEmpty) {
      try {
        final decoded = jsonDecode(directPayload);
        if (decoded is Map<String, dynamic>) {
          return <String, dynamic>{...rawData, ...decoded};
        }
      } catch (_) {
        return Map<String, dynamic>.from(rawData);
      }
    }
    if (directPayload is Map<String, dynamic>) {
      return <String, dynamic>{...rawData, ...directPayload};
    }

    return Map<String, dynamic>.from(rawData);
  }

  void _logGdprNotificationDebug(
    String key,
    Map<String, dynamic> data, {
    required bool fromTap,
  }) {
    final normalized = key.toLowerCase();
    if (!normalized.contains('gdpr')) return;

    final message = data['message'];
    final messageText = message is Map ? message['Text'] : null;
    final messageValue = message is Map ? message['value'] : null;
    final topLevelValue = data['value'];
    final topLevelStatus = data['statusCode'] ?? data['StatusCode'];

    _logEvent(
      'GDPR notification debug => key: $key, normalized: $normalized, fromTap: $fromTap',
    );
    _logEvent(
      'GDPR notification payload => value: $topLevelValue, statusCode: $topLevelStatus, messageText: $messageText, messageValue: $messageValue',
    );
    _logEvent('GDPR raw payload => $data');
  }
}
