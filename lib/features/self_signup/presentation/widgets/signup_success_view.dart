import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';

class SignupSuccessView extends StatelessWidget {
  const SignupSuccessView({super.key, required this.onGoToLogin});
  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 36),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD91F32), width: 2),
          ),
          child: const Icon(Icons.check, size: 36, color: Color(0xFFD91F32)),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            l10n.tr('tns.selfSignupCompleteMsg'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 15,
              color: Color(0xFF2D2D2D),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 36),
        signupBottomButton(
          label: l10n.tr('tns.goToLogin').toUpperCase(),
          isEnabled: true,
          onTap: onGoToLogin,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
