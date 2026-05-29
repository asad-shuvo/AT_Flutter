import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/localization/app_language_scope.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_route_observer.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/app/services/app_services.dart';
import 'package:filip_at_flutter/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FilipAtApp extends StatefulWidget {
  const FilipAtApp({super.key, required this.config, required this.services});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final AppConfig config;
  final AppServices services;

  @override
  State<FilipAtApp> createState() => _FilipAtAppState();
}

class _FilipAtAppState extends State<FilipAtApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle link that launched the app from cold start.
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle links while app is already running — mirrors NS registerUniversalLinkCallback.
    _deepLinkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // NS: setTimeout(() => router.navigate([ul.pathname]), 300)
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      final navigator = FilipAtApp.navigatorKey.currentState;
      if (navigator == null) return;
      // Push the path — router handles /login/reset-password-verification/{code}/{lang}
      navigator.pushNamed(uri.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRouter =
        AppRouter(config: widget.config, services: widget.services);
    widget.services.fcmService.setNavigatorKey(FilipAtApp.navigatorKey);

    return AppLanguageScope(
      controller: widget.services.languageController,
      child: AnimatedBuilder(
        animation: widget.services.languageController,
        builder: (context, _) {
          return MaterialApp(
            title: widget.config.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: widget.services.languageController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: FilipAtApp.navigatorKey,
            navigatorObservers: [appRouteObserver],
            onGenerateRoute: appRouter.onGenerateRoute,
            initialRoute: AppRouter.splash,
          );
        },
      ),
    );
  }
}
