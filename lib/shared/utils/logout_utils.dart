import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:flutter/material.dart';

Future<void> performLogout(
  BuildContext context, {
  required AuthSessionController authSessionController,
}) async {
  final navigator = Navigator.of(context);
  await authSessionController.signOut();
  navigator.pushNamedAndRemoveUntil('/login', (_) => false);
}
