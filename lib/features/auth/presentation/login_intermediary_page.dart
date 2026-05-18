import 'dart:async';

import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/auth/data/login_sync_repository.dart';
import 'package:filip_at_flutter/features/auth/presentation/fingerprint_activation_page.dart';
import 'package:filip_at_flutter/features/auth/presentation/post_login_biometric_sheet.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/settings/application/biometric_service.dart';
import 'package:flutter/material.dart';

class LoginIntermediaryPage extends StatefulWidget {
  const LoginIntermediaryPage({
    super.key,
    required this.userSessionCache,
    required this.loginSyncRepository,
    required this.profileRepository,
    required this.authSessionController,
  });

  final UserSessionCache userSessionCache;
  final LoginSyncRepository loginSyncRepository;
  final ProfileRepository profileRepository;
  final AuthSessionController authSessionController;

  @override
  State<LoginIntermediaryPage> createState() => _LoginIntermediaryPageState();
}

class _LoginIntermediaryPageState extends State<LoginIntermediaryPage> {
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _syncAndNavigate();
  }

  Future<void> _syncAndNavigate() async {
    final session = await widget.userSessionCache.resolve();

    if (session != null && session.customerId.isNotEmpty) {
      unawaited(
        widget.loginSyncRepository.syncCustomerDataById(
          accessToken: session.accessToken,
          customerId: session.customerId,
          userId: session.userId,
          userName: session.displayName,
        ),
      );
      unawaited(
        widget.loginSyncRepository.syncGdprConsentFromKvv(
          accessToken: session.accessToken,
          customerId: session.customerId,
        ),
      );
    }

    if (session != null) {
      unawaited(
        widget.loginSyncRepository.addLoginPlatform(
          accessToken: session.accessToken,
        ),
      );
    }

    if (!mounted) return;

    await _maybeShowBiometricPrompt();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
    }
  }

  Future<void> _maybeShowBiometricPrompt() async {
    final biometricEnabled =
        await widget.profileRepository.getBiometricEnabled();
    final dontAsk =
        await widget.profileRepository.getDontAskBiometricPrompt();
    final hardwareSupported =
        await _biometricService.isHardwareSupported();

    if (!mounted) return;
    if (biometricEnabled || dontAsk || !hardwareSupported) return;

    final shouldEnable = await PostLoginBiometricSheet.show(
      context,
      repository: widget.profileRepository,
    );

    if (!mounted) return;
    if (!shouldEnable) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FingerprintActivationPage(
          authSessionController: widget.authSessionController,
          profileRepository: widget.profileRepository,
          biometricService: _biometricService,
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFD91F32)),
      ),
    );
  }
}
