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
      final denormalizedPayload = message.data['DenormalizedPayload'];
      if (denormalizedPayload == null) {
        _logEvent('No DenormalizedPayload in message');
        return;
      }

      final notificationData = denormalizedPayload is String
          ? jsonDecode(denormalizedPayload) as Map<String, dynamic>
          : denormalizedPayload as Map<String, dynamic>;

      final notificationKey = notificationData['notificationKey'] as String?;
      if (notificationKey == null) {
        _logEvent('No notificationKey found in payload');
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
      default:
        _logEvent('Unhandled tap notification: $key');
    }
  }

  void _handleDataNotification(String key, Map<String, dynamic> data) {
    switch (key) {
      case 'contract_sync_completed':
        _syncNotificationService.contractSyncCompleted.add(data);
        _logEvent('Emitted to contractSyncCompleted');
        break;
      case 'investment_contracts_sync_completed':
        _syncNotificationService.investmentContractSyncCompleted.add(data);
        _logEvent('Emitted to investmentContractSyncCompleted');
        break;
      case 'AssetCalculationCompleted':
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
      case 'synccustomerdatabyid':
        _syncNotificationService.synccustomerdatabyid.add(data);
        _logEvent('Emitted to synccustomerdatabyid');
        break;
      case 'synccustomergdprconsentstatus':
        _syncNotificationService.gdprConsentSync.add(data);
        _logEvent('Emitted to gdprConsentSync');
        break;
      default:
        _logEvent('Unhandled data notification: $key');
    }
  }

  void _logEvent(String message) {
    // ignore: avoid_print
    print('[FCM] $message');
  }
}
