import 'dart:convert';
import 'dart:typed_data';

import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/data/forgot_password_repository.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

enum _ForgotPasswordStage { emailInput, emailSent }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.repository});

  final ForgotPasswordRepository repository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  _ForgotPasswordStage _stage = _ForgotPasswordStage.emailInput;

  final _emailController = TextEditingController();
  final _captchaController = TextEditingController();

  ForgotPasswordCaptcha? _captcha;
  Uint8List? _captchaBytes;
  String _captchaBase64Cached = '';

  bool _captchaLoading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.repository.resetSession();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Uint8List? get _captchaBytesDecoded {
    final b64 = _captcha?.imageBase64 ?? '';
    if (b64 != _captchaBase64Cached) {
      _captchaBase64Cached = b64;
      _captchaBytes = b64.isNotEmpty ? base64Decode(b64) : null;
    }
    return _captchaBytes;
  }

  Future<void> _loadCaptcha() async {
    setState(() {
      _captchaLoading = true;
      _captcha = null;
      _captchaBase64Cached = '';
      _captchaBytes = null;
      _captchaController.clear();
    });
    try {
      final captcha = await widget.repository.createCaptcha();
      if (!mounted) return;
      setState(() {
        _captcha = captcha;
        _captchaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _captchaLoading = false);
    }
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final captchaValue = _captchaController.text.trim();
    return email.isNotEmpty &&
        captchaValue.isNotEmpty &&
        RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _onContinue() async {
    if (_stage == _ForgotPasswordStage.emailSent) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
      return;
    }

    if (!_isFormValid || _captcha == null || _submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final l10n = context.l10n;

    try {
      final captchaResult = await widget.repository.submitCaptcha(
        captchaId: _captcha!.id,
        value: _captchaController.text.trim(),
      );

      if (!mounted) return;

      if (!captchaResult.isMatched) {
        setState(() {
          _submitting = false;
          _errorMessage = l10n.tr('tns.captchaNotMatchError');
        });
        await _loadCaptcha();
        return;
      }

      final result = await widget.repository.recoverAccount(
        email: _emailController.text.trim(),
        verificationCode: captchaResult.verificationCode,
      );

      if (!mounted) return;

      switch (result) {
        case RecoverAccountResult.success:
          setState(() {
            _stage = _ForgotPasswordStage.emailSent;
            _submitting = false;
            _errorMessage = null;
          });
        case RecoverAccountResult.emailNotFound:
          setState(() => _submitting = false);
          _showSnackBar(l10n.tr('tns.emailNotFound'));
          await _loadCaptcha();
        case RecoverAccountResult.captchaNotMatched:
          setState(() {
            _submitting = false;
            _errorMessage = l10n.tr('tns.captchaNotMatchError');
          });
          await _loadCaptcha();
        case RecoverAccountResult.error:
          setState(() => _submitting = false);
          _showSnackBar(l10n.tr('SOMETHING_WENT_WRONG'));
          await _loadCaptcha();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnackBar(l10n.tr('SOMETHING_WENT_WRONG'));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmailSent = _stage == _ForgotPasswordStage.emailSent;
    final continueEnabled =
        isEmailSent || (_isFormValid && !_submitting && _captcha != null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onCancel: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _EnvelopeImage(sent: isEmailSent),
                    const SizedBox(height: 24),
                    Text(
                      isEmailSent
                          ? l10n.tr('tns.emailHasBeenSentHeader')
                          : l10n.tr('tns.setYourEmailHeader'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        fontSize: 28,
                        color: Color(0xFF5A5551),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEmailSent
                          ? l10n.tr('tns.emailHasBeenSentSubHeader')
                          : l10n.tr('tns.setYourEmailSubHeaderSubHeader'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    if (!isEmailSent) ...[
                      const SizedBox(height: 28),
                      _FieldLabel(l10n.tr('tns.email')),
                      const SizedBox(height: 8),
                      _EmailField(controller: _emailController, onChanged: () => setState(() {})),
                      const SizedBox(height: 20),
                      _CaptchaRow(
                        loading: _captchaLoading,
                        captchaBytes: _captchaBytesDecoded,
                        onRefresh: _loadCaptcha,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel(l10n.tr('tns.captcha')),
                      const SizedBox(height: 8),
                      _CaptchaField(
                        controller: _captchaController,
                        onChanged: () => setState(() {}),
                        onSubmit: _onContinue,
                        hasError: _errorMessage != null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontSize: 13,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _ContinueButton(
              label: l10n.tr('tns.setYourEmailFooterButton'),
              enabled: continueEnabled,
              loading: _submitting,
              onTap: _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onCancel});
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Text(
              l10n.tr('tns.cancel').toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryRed,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopeImage extends StatelessWidget {
  const _EnvelopeImage({required this.sent});
  final bool sent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Image.network(
          'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/onboarding_email.png',
          width: 130,
          height: 130,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.mail_outline,
            size: 80,
            color: Color(0xFFCCCCCC),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text *',
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 13,
        color: Color(0xFF808080),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: (_) => onChanged(),
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: l10n.tr('tns.setYourEmailPlaceholder1'),
        hintStyle: const TextStyle(
          fontFamily: 'Calibri',
          color: Color(0xFFA6A6A6),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: const BorderSide(color: Color(0xFFC9C9C9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: const BorderSide(color: Color(0xFFC9C9C9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.2),
        ),
      ),
    );
  }
}

class _CaptchaRow extends StatelessWidget {
  const _CaptchaRow({
    required this.loading,
    required this.captchaBytes,
    required this.onRefresh,
  });
  final bool loading;
  final Uint8List? captchaBytes;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              border: Border.all(color: const Color(0xFFD0C080), width: 0.8),
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : captchaBytes != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppFormTokens.fieldRadius),
                        child: Image.memory(
                          captchaBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: loading ? null : onRefresh,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.refresh, size: 26, color: Color(0xFF555555)),
        ),
      ],
    );
  }
}

class _CaptchaField extends StatelessWidget {
  const _CaptchaField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    required this.hasError,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: l10n.tr('tns.setYourEmailPlaceholder2'),
        hintStyle: const TextStyle(
          fontFamily: 'Calibri',
          color: Color(0xFFA6A6A6),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: BorderSide(
            color: hasError ? AppColors.primaryRed : const Color(0xFFC9C9C9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: BorderSide(
            color: hasError ? AppColors.primaryRed : const Color(0xFFC9C9C9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.2),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            disabledBackgroundColor: const Color(0xFFD3D3D3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppFormTokens.buttonRadius),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
