import 'package:filip_at_flutter/app/flavor/app_flavor.dart';

class AppEnvironment {
  const AppEnvironment({
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
    required this.signupServiceUrl,
    required this.captchaUrl,
    required this.appVersion,
    required this.investmentPushNotificationKey,
  });

  factory AppEnvironment.fromFlavor(AppFlavor flavor) {
    const devBaseUrl = 'http://msblocks.seliselocal.com/api';
    const stgBaseUrl = 'https://msblocks.selisestage.com/api';
    const uatBaseUrl = 'https://msblocks.seliseuat.com/api';
    const prodBaseUrl = 'https://www.filip.at/api';
    const devOriginUrl = 'http://sln-at.seliselocal.com';
    const stgOriginUrl = 'https://sln-at.selisestage.com';
    const uatOriginUrl = 'https://sln-at.seliseuat.com';
    const prodOriginUrl = 'https://www.filip.at';
    const cdnBaseUrl = 'https://cdn.selise.biz/slnetwork/';

    switch (flavor) {
      case AppFlavor.dev:
        return const AppEnvironment(
          apiBaseUrl: devBaseUrl,
          tokenUrl: '$devBaseUrl/identity/v20/identity/token',
          dataCoreUrl: '$devBaseUrl/pds/v1/AppSuiteDataCore/',
          snQueryUrl:
              '$devBaseUrl/business-slnquery/selectnetworkqueryservice/',
          slsnBusinessUrl:
              '$devBaseUrl/business-sln/SelectNetworkBusinessService/',
          notificationUrl: '$devBaseUrl/notification/v3',
          dfsBaseUrl: 'http://pms-swisslife-frontend-dev.additiv.com/',
          originUrl: devOriginUrl,
          cdnBaseUrl: cdnBaseUrl,
          storageServiceUrl: '$devBaseUrl/storageservice/v22/StorageService/',
          dmsServiceUrl: '$devBaseUrl/dms/v40/DmsService/',
          signupServiceUrl: '$devBaseUrl/signup/SignupService/',
          captchaUrl: '$devBaseUrl/captcha/v1/Captcha/CaptchaCommand/',
          appVersion: '1.0.4.23.1.2024',
          investmentPushNotificationKey: '033c1c1a-3b1c-4bd2-bf9a-dc8009f2de63',
        );
      case AppFlavor.stg:
        return const AppEnvironment(
          apiBaseUrl: stgBaseUrl,
          tokenUrl: '$stgBaseUrl/identity/v25/identity/token',
          dataCoreUrl: '$stgBaseUrl/pds/v1/AppSuiteDataCore/',
          snQueryUrl:
              '$stgBaseUrl/business-slnquery/selectnetworkqueryservice/',
          slsnBusinessUrl:
              '$stgBaseUrl/business-sln/SelectNetworkBusinessService/',
          notificationUrl: '$stgBaseUrl/notification/v3',
          dfsBaseUrl: 'http://pms-swisslife-frontend-test.additiv.com/',
          originUrl: stgOriginUrl,
          cdnBaseUrl: cdnBaseUrl,
          storageServiceUrl: '$stgBaseUrl/storageservice/v23/StorageService/',
          dmsServiceUrl: '$stgBaseUrl/dms/v46/DmsService/',
          signupServiceUrl: '$stgBaseUrl/signup/SignupService/',
          captchaUrl: '$stgBaseUrl/captcha/v1/Captcha/CaptchaCommand/',
          appVersion: '1.0.4',
          investmentPushNotificationKey: '4594019c-5f57-467d-bfbb-f2b6f08dd94c',
        );
      case AppFlavor.uat:
        return const AppEnvironment(
          apiBaseUrl: uatBaseUrl,
          tokenUrl: '$uatBaseUrl/identity/v25/identity/token',
          dataCoreUrl: '$uatBaseUrl/pds/v1/AppSuiteDataCore/',
          snQueryUrl:
              '$uatBaseUrl/business-slnquery/selectnetworkqueryservice/',
          slsnBusinessUrl:
              '$uatBaseUrl/business-sln/SelectNetworkBusinessService/',
          notificationUrl: '$uatBaseUrl/notification/v3',
          dfsBaseUrl: 'https://stagefilip.swisslife-select.at/',
          originUrl: uatOriginUrl,
          cdnBaseUrl: cdnBaseUrl,
          storageServiceUrl: '$uatBaseUrl/storageservice/v23/StorageService/',
          dmsServiceUrl: '$uatBaseUrl/dms/v46/DmsService/',
          signupServiceUrl: '$uatBaseUrl/signup/SignupService/',
          captchaUrl: '$uatBaseUrl/captcha/v1/Captcha/CaptchaCommand/',
          appVersion: '19.04.2026',
          investmentPushNotificationKey: '4594019c-5f57-467d-bfbb-f2b6f08dd94c',
        );
      case AppFlavor.prod:
        return const AppEnvironment(
          apiBaseUrl: prodBaseUrl,
          tokenUrl: '$prodBaseUrl/identity/v100/identity/token',
          dataCoreUrl: '$prodBaseUrl/pds/v100/AppSuiteDataCore/',
          snQueryUrl:
              '$prodBaseUrl/business-slnquery/selectnetworkqueryservice/',
          slsnBusinessUrl:
              '$prodBaseUrl/business-sln/SelectNetworkBusinessService/',
          notificationUrl: '$prodBaseUrl/notification/v100',
          dfsBaseUrl: 'https://filip.swisslife-select.at/',
          originUrl: prodOriginUrl,
          cdnBaseUrl: cdnBaseUrl,
          storageServiceUrl: '$prodBaseUrl/storageservice/v100/StorageService/',
          dmsServiceUrl: '$prodBaseUrl/dms/v100/DmsService/',
          signupServiceUrl: '$prodBaseUrl/signup/SignupService/',
          captchaUrl: '$prodBaseUrl/captcha/v100/Captcha/CaptchaCommand/',
          appVersion: '1.0.15',
          investmentPushNotificationKey: '4594019c-5f57-467d-bfbb-f2b6f08dd94c',
        );
    }
  }

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
  final String signupServiceUrl;
  final String captchaUrl;
  final String appVersion;
  final String investmentPushNotificationKey;
}
