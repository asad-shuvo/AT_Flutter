import 'package:filip_at_flutter/app/environment/app_environment.dart';
import 'package:filip_at_flutter/app/flavor/app_flavor.dart';
import 'package:filip_at_flutter/core/constants/app_constants.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.tokenUrl,
    required this.dataCoreUrl,
    required this.snQueryUrl,
    required this.slsnBusinessUrl,
    required this.notificationUrl,
    required this.dfsBaseUrl,
    required this.originUrl,
    required this.cdnBaseUrl,
    required this.storageServiceUrl,
    required this.dmsServiceUrl,
    required this.appVersion,
    required this.investmentPushNotificationKey,
  });

  factory AppConfig.fromFlavor(AppFlavor flavor) {
    final environment = AppEnvironment.fromFlavor(flavor);

    return AppConfig(
      flavor: flavor,
      appName: AppConstants.appName,
      apiBaseUrl: environment.apiBaseUrl,
      tokenUrl: environment.tokenUrl,
      dataCoreUrl: environment.dataCoreUrl,
      snQueryUrl: environment.snQueryUrl,
      slsnBusinessUrl: environment.slsnBusinessUrl,
      notificationUrl: environment.notificationUrl,
      dfsBaseUrl: environment.dfsBaseUrl,
      originUrl: environment.originUrl,
      cdnBaseUrl: environment.cdnBaseUrl,
      storageServiceUrl: environment.storageServiceUrl,
      dmsServiceUrl: environment.dmsServiceUrl,
      appVersion: environment.appVersion,
      investmentPushNotificationKey: environment.investmentPushNotificationKey,
    );
  }

  final AppFlavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String tokenUrl;
  final String dataCoreUrl;
  final String snQueryUrl;
  final String slsnBusinessUrl;
  final String notificationUrl;
  final String dfsBaseUrl;
  final String originUrl;
  final String cdnBaseUrl;
  final String storageServiceUrl;
  final String dmsServiceUrl;
  final String appVersion;
  final String investmentPushNotificationKey;

  bool get isProduction => flavor == AppFlavor.prod;
}
