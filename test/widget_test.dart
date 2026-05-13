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
import 'package:filip_at_flutter/features/auth/data/login_sync_repository.dart';
import 'package:filip_at_flutter/features/contracts/application/household_member_filter_controller.dart';
import 'package:filip_at_flutter/features/contracts/data/contracts_repository.dart';
import 'package:filip_at_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:filip_at_flutter/features/drive/data/drive_repository.dart';
import 'package:filip_at_flutter/features/notifications/data/notifications_repository.dart';
import 'package:filip_at_flutter/features/notifications/application/sync_notification_service.dart';
import 'package:filip_at_flutter/features/notifications/application/fcm_service.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/self_signup/data/self_signup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('renders app shell', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final secureStorageService = await SecureStorageService.create();
    final apiClient = ApiClient(
      baseUrl: 'https://msblocks.selisestage.com/api',
      tokenUrl:
          'https://msblocks.selisestage.com/api/identity/v25/identity/token',
      dataCoreUrl:
          'https://msblocks.selisestage.com/api/pds/v1/AppSuiteDataCore/',
      snQueryUrl:
          'https://msblocks.selisestage.com/api/business-slnquery/selectnetworkqueryservice/',
      slsnBusinessUrl:
          'https://msblocks.selisestage.com/api/business-sln/SelectNetworkBusinessService/',
      notificationUrl: 'https://msblocks.selisestage.com/api/notification/v3',
      originUrl: 'https://sln-at.selisestage.com',
      dfsBaseUrl: 'http://pms-swisslife-frontend-test.additiv.com/',
      storageServiceUrl:
          'https://msblocks.selisestage.com/api/storageservice/v23/StorageService/',
      dmsServiceUrl: 'https://msblocks.selisestage.com/api/dms/v46/DmsService/',
      aggregatorUrl: 'https://msblocks.selisestage.com/api/aggregator/v4/Service-Aggregator/ServiceAggrigation/',
      mailServiceUrl: 'https://msblocks.selisestage.com/api/mailservice/v15/MailService',
    );
    final authRepository = AuthRepository(
      apiClient: apiClient,
      secureStorageService: secureStorageService,
    );

    final authSessionController = AuthSessionController(
      authRepository: authRepository,
    );

    const config = AppConfig(
      flavor: AppFlavor.dev,
      appName: 'Filip AT',
      apiBaseUrl: 'https://msblocks.selisestage.com/api',
      tokenUrl:
          'https://msblocks.selisestage.com/api/identity/v25/identity/token',
      dataCoreUrl:
          'https://msblocks.selisestage.com/api/pds/v1/AppSuiteDataCore/',
      snQueryUrl:
          'https://msblocks.selisestage.com/api/business-slnquery/selectnetworkqueryservice/',
      slsnBusinessUrl:
          'https://msblocks.selisestage.com/api/business-sln/SelectNetworkBusinessService/',
      notificationUrl: 'https://msblocks.selisestage.com/api/notification/v3',
      dfsBaseUrl: 'http://pms-swisslife-frontend-test.additiv.com/',
      originUrl: 'https://sln-at.selisestage.com',
      cdnBaseUrl: 'https://cdn.selise.biz/slnetwork/',
      storageServiceUrl: 'https://msblocks.selisestage.com/api/storage/',
      dmsServiceUrl: 'https://msblocks.selisestage.com/api/dms/',
      signupServiceUrl: 'https://msblocks.selisestage.com/api/signup/SignupService/',
      captchaUrl: 'https://msblocks.selisestage.com/api/captcha/v1/Captcha/CaptchaCommand/',
      appVersion: '1.0.4',
      investmentPushNotificationKey: '033c1c1a-3b1c-4bd2-bf9a-dc8009f2de63',
      aggregatorUrl: 'https://msblocks.selisestage.com/api/aggregator/v4/Service-Aggregator/ServiceAggrigation/',
      mailServiceUrl: 'https://msblocks.selisestage.com/api/mailservice/v15/MailService',
    );
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

    final syncNotificationService = SyncNotificationService();
    final fcmService = FcmService(
      syncNotificationService: syncNotificationService,
      secureStorage: secureStorageService,
    );

    final selfSignupRepository = SelfSignupRepository(
      apiClient: apiClient,
      signupServiceUrl: 'https://msblocks.selisestage.com/api/signup/SignupService/',
      captchaUrl: 'https://msblocks.selisestage.com/api/captcha/v1/Captcha/CaptchaCommand/',
      originUrl: 'https://sln-at.selisestage.com',
      tokenUrl: 'https://msblocks.selisestage.com/api/identity/v25/identity/token',
    );
    final driveRepository = DriveRepository(
      apiClient: apiClient,
      userSessionCache: userSessionCache,
    );
    final profileRepository = ProfileRepository(
      apiClient: apiClient,
      userSessionCache: userSessionCache,
      captchaUrl:
          'https://msblocks.selisestage.com/api/captcha/v1/Captcha/CaptchaCommand/',
    );
    final services = AppServices(
      apiClient: apiClient,
      secureStorageService: secureStorageService,
      authRepository: authRepository,
      authSessionController: authSessionController,
      userSessionCache: userSessionCache,
      loginSyncRepository: LoginSyncRepository(apiClient: apiClient),
      dashboardRepository: dashboardRepository,
      contractsRepository: contractsRepository,
      notificationsRepository: notificationsRepository,
      languageController: languageController,
      syncNotificationService: syncNotificationService,
      fcmService: fcmService,
      selfSignupRepository: selfSignupRepository,
      householdController: HouseholdMemberFilterController(
        contractsRepository: contractsRepository,
      ),
      driveRepository: driveRepository,
      profileRepository: profileRepository,
    );

    await tester.pumpWidget(FilipAtApp(config: config, services: services));

    expect(find.byType(FilipAtApp), findsOneWidget);
  });
}
