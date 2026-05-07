import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/localization/app_language_scope.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_route_observer.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/app/services/app_services.dart';
import 'package:filip_at_flutter/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FilipAtApp extends StatelessWidget {
  const FilipAtApp({super.key, required this.config, required this.services});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AppConfig config;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(config: config, services: services);
    services.fcmService.setNavigatorKey(navigatorKey);

    return AppLanguageScope(
      controller: services.languageController,
      child: AnimatedBuilder(
        animation: services.languageController,
        builder: (context, _) {
          return MaterialApp(
            title: config.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: services.languageController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: navigatorKey,
            navigatorObservers: [appRouteObserver],
            onGenerateRoute: appRouter.onGenerateRoute,
            initialRoute: AppRouter.splash,
          );
        },
      ),
    );
  }
}
