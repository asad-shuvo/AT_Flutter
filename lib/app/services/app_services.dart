import 'package:filip_at_flutter/app/localization/app_language_controller.dart';
import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:filip_at_flutter/features/app_version/data/app_version_repository.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/auth/data/auth_repository.dart';
import 'package:filip_at_flutter/features/auth/data/forgot_password_repository.dart';
import 'package:filip_at_flutter/features/auth/data/login_sync_repository.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/fcm_service.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/self_signup/data/self_signup_repository.dart';
import 'package:filip_at_flutter/features/survey/data/survey_address_repository.dart';

class AppServices {
  const AppServices({
    required this.apiClient,
    required this.secureStorageService,
    required this.authRepository,
    required this.forgotPasswordRepository,
    required this.authSessionController,
    required this.userSessionCache,
    required this.loginSyncRepository,
    required this.dashboardRepository,
    required this.contractsRepository,
    required this.notificationsRepository,
    required this.languageController,
    required this.syncNotificationService,
    required this.fcmService,
    required this.selfSignupRepository,
    required this.householdController,
    required this.driveRepository,
    required this.profileRepository,
    required this.surveyAddressRepository,
    required this.appVersionRepository,
  });

  final ApiClient apiClient;
  final SecureStorageService secureStorageService;
  final AuthRepository authRepository;
  final ForgotPasswordRepository forgotPasswordRepository;
  final AuthSessionController authSessionController;
  final UserSessionCache userSessionCache;
  final LoginSyncRepository loginSyncRepository;
  final DashboardRepository dashboardRepository;
  final ContractsRepository contractsRepository;
  final NotificationsRepository notificationsRepository;
  final AppLanguageController languageController;
  final SyncNotificationService syncNotificationService;
  final FcmService fcmService;
  final SelfSignupRepository selfSignupRepository;
  final HouseholdMemberFilterController householdController;
  final DriveRepository driveRepository;
  final ProfileRepository profileRepository;
  final SurveyAddressRepository surveyAddressRepository;
  final AppVersionRepository appVersionRepository;
}
