import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:filip_at_flutter/app/app.dart';
import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/flavor/app_flavor.dart';
import 'package:filip_at_flutter/app/localization/app_language_controller.dart';
import 'package:filip_at_flutter/app/services/app_services.dart';
import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/auth/data/auth_repository.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/fcm_service.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Handle background message - just logging for now
  // Data sync happens when app resumes via event listeners
  // ignore: avoid_print
  print('[FCM Background] Received message: ${message.data}');
}

Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  final config = AppConfig.fromFlavor(flavor);
  final apiClient = ApiClient(
    baseUrl: config.apiBaseUrl,
    tokenUrl: config.tokenUrl,
    dataCoreUrl: config.dataCoreUrl,
    snQueryUrl: config.snQueryUrl,
    slsnBusinessUrl: config.slsnBusinessUrl,
    notificationUrl: config.notificationUrl,
    dfsBaseUrl: config.dfsBaseUrl,
    originUrl: config.originUrl,
    storageServiceUrl: config.storageServiceUrl,
    dmsServiceUrl: config.dmsServiceUrl,
  );
  final secureStorageService = await SecureStorageService.create();
  final authRepository = AuthRepository(
    apiClient: apiClient,
    secureStorageService: secureStorageService,
  );
  final authSessionController = AuthSessionController(
    authRepository: authRepository,
  );
  var isHandlingUnauthorized = false;
  apiClient.setUnauthorizedHandler(() async {
    if (isHandlingUnauthorized || !authSessionController.isAuthenticated) {
      return;
    }

    isHandlingUnauthorized = true;
    try {
      await authSessionController.expireSession();

      final navigator = FilipAtApp.navigatorKey.currentState;
      final context = FilipAtApp.navigatorKey.currentContext;

      navigator?.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);

      if (context != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Your session expired. Please log in again.'),
            ),
          );
      }
    } finally {
      isHandlingUnauthorized = false;
    }
  });
  final userSessionCache = UserSessionCache(
    apiClient: apiClient,
    secureStorageService: secureStorageService,
  );
  final dashboardRepository = DashboardRepository(
    apiClient: apiClient,
    userSessionCache: userSessionCache,
  );
  final contractsRepository = ContractsRepository(
    apiClient: apiClient,
    userSessionCache: userSessionCache,
  );
  final notificationsRepository = NotificationsRepository(
    apiClient: apiClient,
    secureStorageService: secureStorageService,
  );
  final languageController = AppLanguageController(
    secureStorageService: secureStorageService,
  );

  // Firebase & FCM initialization
  final syncNotificationService = SyncNotificationService();
  final fcmService = FcmService(
    syncNotificationService: syncNotificationService,
    secureStorage: secureStorageService,
  );
  await fcmService.initializeFirebase();
  await fcmService.setupMessaging(config.investmentPushNotificationKey);
  fcmService.startListening();

  await authSessionController.restoreSession();
  await languageController.restoreLocale();

  final services = AppServices(
    apiClient: apiClient,
    secureStorageService: secureStorageService,
    authRepository: authRepository,
    authSessionController: authSessionController,
    userSessionCache: userSessionCache,
    dashboardRepository: dashboardRepository,
    contractsRepository: contractsRepository,
    notificationsRepository: notificationsRepository,
    languageController: languageController,
    syncNotificationService: syncNotificationService,
    fcmService: fcmService,
  );

  // Wire auth state changes for FCM topic subscription and session cache invalidation
  authSessionController.addListener(() {
    _handleAuthStateChange(
      authSessionController,
      secureStorageService,
      fcmService,
      contractsRepository,
      syncNotificationService,
      userSessionCache,
    );
  });

  // Wire external contract sync completion to trigger document download
  syncNotificationService.externalContractSyncCompleted.stream.listen((_) {
    _handleExternalContractSync(secureStorageService, contractsRepository);
  });

  runApp(FilipAtApp(config: config, services: services));
}

Future<void> _handleAuthStateChange(
  AuthSessionController authSessionController,
  SecureStorageService secureStorageService,
  FcmService fcmService,
  ContractsRepository contractsRepository,
  SyncNotificationService syncNotificationService,
  UserSessionCache userSessionCache,
) async {
  final isAuthenticated = authSessionController.isAuthenticated;

  if (isAuthenticated) {
    final accessToken = await secureStorageService.read('access_token');
    if (accessToken != null && accessToken.isNotEmpty) {
      final userId = _extractUserIdFromToken(accessToken);
      if (userId.isNotEmpty) {
        await fcmService.subscribeToUserTopic(userId);
      }
    }
  } else {
    userSessionCache.invalidate();
    final previousTopic = await secureStorageService.read('firebase_topic');
    if (previousTopic != null && previousTopic.isNotEmpty) {
      await fcmService.unsubscribeFromUserTopic(previousTopic);
    }
  }
}

Future<void> _handleExternalContractSync(
  SecureStorageService secureStorageService,
  ContractsRepository contractsRepository,
) async {
  final customerId = await secureStorageService.read('customer_id');
  final userId = await secureStorageService.read('user_id');

  if (customerId != null && userId != null) {
    await contractsRepository.syncCustomerDocument(
      customerId: customerId,
      userId: userId,
    );
  }
}

String _extractUserIdFromToken(String accessToken) {
  try {
    final parts = accessToken.split('.');
    if (parts.length != 3) return '';
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return decoded['user_id'] as String? ?? '';
  } catch (e) {
    // ignore: avoid_print
    print('[Bootstrap] Error extracting userId from token: $e');
    return '';
  }
}
