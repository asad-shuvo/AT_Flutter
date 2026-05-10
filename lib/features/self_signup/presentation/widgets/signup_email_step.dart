import 'dart:convert';
import 'dart:typed_data';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';

class SignupEmailStep extends StatefulWidget {
  const SignupEmailStep({super.key, required this.controller});
  final SelfSignupController controller;

  @override
  State<SignupEmailStep> createState() => _SignupEmailStepState();
}

class _SignupEmailStepState extends State<SignupEmailStep> {
  final _emailController = TextEditingController();
  final _captchaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  // Cache decoded bytes so Image.memory doesn't reload on every keystroke.
  Uint8List? _captchaBytes;
  String _captchaBase64Cached = '';

  Uint8List? _getCaptchaBytes() {
    final b64 = widget.controller.captchaImageBase64;
    if (b64 != _captchaBase64Cached) {
      _captchaBase64Cached = b64;
      _captchaBytes = b64.isNotEmpty ? base64Decode(b64) : null;
    }
    return _captchaBytes;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _checkValid() {
    final ok =
        _emailController.text.trim().isNotEmpty &&
        _captchaController.text.trim().isNotEmpty &&
        RegExp(
          r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(_emailController.text.trim());
    if (ok != _isValid) setState(() => _isValid = ok);
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    final ok = await widget.controller.submitCaptchaAndProceed(
      _captchaController.text.trim(),
    );
    if (!ok) return;
    if (mounted) {
      await widget.controller.sendEmailCode(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildIllustration(),
                  const SizedBox(height: 20),
                  Text(
                    l10n.tr('tns.yourEmailAddress'),
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontStyle: FontStyle.italic,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.tr(
                      'tns.pleaseProvideYourEmailAddressToRegisterANewAccount',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Calibri',
                      fontSize: 14,
                      color: Color(0xFF7A7A7A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  signupFieldLabel('${l10n.tr('tns.email')} *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _checkValid(),
                    style: signupInputStyle,
                    decoration: signupInputDecoration(l10n.tr('tns.email')),
                  ),
                  const SizedBox(height: 20),
                  if (c.isCaptchaLoading)
                    const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD91F32),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    _buildCaptchaImage(c),
                  const SizedBox(height: 10),
                  signupFieldLabel('${l10n.tr('tns.captcha')} *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _captchaController,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _checkValid(),
                    onFieldSubmitted: (_) => _submit(),
                    style: signupInputStyle,
                    decoration: signupInputDecoration(l10n.tr('tns.captcha')),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        signupBottomButton(
          label: '${l10n.tr('tns.continue').toUpperCase()} >',
          isEnabled: _isValid && !c.isLoading,
          isLoading: c.isLoading,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Image.network(
      'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/onboarding_email.png',
      width: 130,
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.mail_outline, size: 80, color: Color(0xFFD91F32)),
    );
  }

  Widget _buildCaptchaImage(SelfSignupController c) {
    final bytes = _getCaptchaBytes();
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              border: Border.all(color: const Color(0xFFD0C080), width: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      bytes,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: c.loadCaptcha,
          icon: const Icon(Icons.refresh, color: Color(0xFF555555), size: 24),
        ),
      ],
    );
  }
}
