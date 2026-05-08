import 'dart:async';

import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/auth/data/login_sync_repository.dart';
import 'package:flutter/material.dart';

class LoginIntermediaryPage extends StatefulWidget {
  const LoginIntermediaryPage({
    super.key,
    required this.userSessionCache,
    required this.loginSyncRepository,
  });

  final UserSessionCache userSessionCache;
  final LoginSyncRepository loginSyncRepository;

  @override
  State<LoginIntermediaryPage> createState() => _LoginIntermediaryPageState();
}

class _LoginIntermediaryPageState extends State<LoginIntermediaryPage> {
  @override
  void initState() {
    super.initState();
    _syncAndNavigate();
  }

  Future<void> _syncAndNavigate() async {
    final session = await widget.userSessionCache.resolve();

    if (session != null && session.customerId.isNotEmpty) {
      // Fire-and-forget: mirrors NativeScript intermediary page behavior —
      // sync calls are dispatched but navigation does not wait for them.
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

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
    }
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
