import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:filip_at_flutter/features/app_version/data/app_version_repository.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.config,
    required this.authSessionController,
    required this.appVersionRepository,
    required this.secureStorageService,
  });

  final AppConfig config;
  final AuthSessionController authSessionController;
  final AppVersionRepository appVersionRepository;
  final SecureStorageService secureStorageService;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  Future<void> _navigate() async {
    final token = await widget.secureStorageService.read(
      AppStorageKeys.accessToken,
    );
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      final status =
          await widget.appVersionRepository.checkAppVersion(token);
      if (!mounted) return;

      if (status == AppVersionStatus.maintenance) {
        Navigator.of(context)
            .pushReplacementNamed(AppRouter.maintenance);
        return;
      }
      if (status == AppVersionStatus.forceUpdate) {
        Navigator.of(context)
            .pushReplacementNamed(AppRouter.forceUpdate);
        return;
      }
    }

    final nextRoute = widget.authSessionController.hasCompletedFirstLogin
        ? AppRouter.login
        : AppRouter.onboarding;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/login/splash_logo.png',
            width: 192,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
