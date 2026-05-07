import 'package:filip_at_flutter/app/config/app_config.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.config,
    required this.authSessionController,
  });

  final AppConfig config;
  final AuthSessionController authSessionController;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nextRoute = widget.authSessionController.hasCompletedFirstLogin
          ? AppRouter.login
          : AppRouter.onboarding;

      Navigator.of(context).pushReplacementNamed(nextRoute);
    });
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
