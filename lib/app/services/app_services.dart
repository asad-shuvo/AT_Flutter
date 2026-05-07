import 'package:filip_at_flutter/app/localization/app_language_controller.dart';
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

class AppServices {
  const AppServices({
    required this.apiClient,
    required this.secureStorageService,
    required this.authRepository,
    required this.authSessionController,
    required this.userSessionCache,
    required this.dashboardRepository,
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.languageController,
    required this.syncNotificationService,
    required this.fcmService,
  });

  final ApiClient apiClient;
  final SecureStorageService secureStorageService;
  final AuthRepository authRepository;
  final AuthSessionController authSessionController;
  final UserSessionCache userSessionCache;
  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AppLanguageController languageController;
  final SyncNotificationService syncNotificationService;
  final FcmService fcmService;
}
