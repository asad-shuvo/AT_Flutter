import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/services/app_services.dart';
import 'package:filip_at_flutter/features/auth/presentation/forgot_password_page.dart';
import 'package:filip_at_flutter/features/auth/presentation/login_page.dart';
import 'package:filip_at_flutter/features/dashboard/presentation/dashboard_page.dart';
import 'package:filip_at_flutter/features/onboarding/presentation/onboarding_page.dart';
import 'package:filip_at_flutter/features/splash/presentation/splash_page.dart';
import 'package:flutter/material.dart';

class AppRouter {
  AppRouter({
    required this.config,
    required this.services,
  });

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/login/forgot-password';
  static const String dashboard = '/dashboard';

  final AppConfig config;
  final AppServices services;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(
          builder: (_) => SplashPage(
            config: config,
            authSessionController: services.authSessionController,
          ),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => LoginPage(
            config: config,
            authSessionController: services.authSessionController,
          ),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingPage(),
          settings: settings,
        );
      case forgotPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );
      case dashboard:
        return MaterialPageRoute<void>(
          builder: (_) => DashboardPage(
            config: config,
            dashboardRepository: services.dashboardRepository,
            contractsRepository: services.contractsRepository,
            notificationsRepository: services.notificationsRepository,
            authSessionController: services.authSessionController,
            syncNotificationService: services.syncNotificationService,
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => SplashPage(
            config: config,
            authSessionController: services.authSessionController,
          ),
          settings: settings,
        );
    }
  }
}
