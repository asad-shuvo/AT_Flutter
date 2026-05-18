import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/app/router/app_router.dart';
import 'package:filip_at_flutter/features/auth/application/auth_session_controller.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/settings/application/biometric_service.dart';
import 'package:filip_at_flutter/features/settings/presentation/recovery_pin_page.dart';
import 'package:filip_at_flutter/features/settings/presentation/set_pin_page.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';

class FingerprintActivationPage extends StatefulWidget {
  const FingerprintActivationPage({
    super.key,
    required this.authSessionController,
    required this.profileRepository,
    required this.biometricService,
    this.prefillEmail = '',
    this.navigateToDashboardOnSuccess = false,
  });

  final AuthSessionController authSessionController;
  final ProfileRepository profileRepository;
  final BiometricService biometricService;
  final String prefillEmail;
  final bool navigateToDashboardOnSuccess;

  @override
  State<FingerprintActivationPage> createState() =>
      _FingerprintActivationPageState();
}

class _FingerprintActivationPageState
    extends State<FingerprintActivationPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;
  bool _isPasswordHidden = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.prefillEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _termsAccepted &&
      !_submitting;

  Future<void> _onContinue() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await widget.authSessionController.signIn(
        username: email,
        password: password,
      );

      if (!mounted) return;

      final hasPinSet = await widget.profileRepository.getPinStatus();

      if (!mounted) return;

      setState(() => _submitting = false);

      final bool? activated;
      if (hasPinSet) {
        activated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => RecoveryPinPage(
              repository: widget.profileRepository,
              biometricService: widget.biometricService,
            ),
          ),
        );
      } else {
        activated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => SetPinPage(
              repository: widget.profileRepository,
              biometricService: widget.biometricService,
            ),
          ),
        );
      }

      if (!mounted) return;

      if (activated == true) {
        await widget.profileRepository.setBiometricEnabled(enabled: true);
        if (!mounted) return;
        if (widget.navigateToDashboardOnSuccess) {
          Navigator.of(context)
              .pushReplacementNamed(AppRouter.loginIntermediary);
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final msg = e.toString().contains('incorrect_user_name_or_password')
          ? l10n.tr('tns.incorrectUserNameOrPin')
          : l10n.tr('SOMETHING_WENT_WRONG');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: const Icon(
                      FilipIcons.back,
                      size: 22,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Image.network(
                        'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/fingerprint_activation.png',
                        width: 100,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, _, _) => const Icon(
                          SelectNetworkIcons.fingerprint,
                          size: 100,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.tr('tns.fingerActivation'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        fontSize: 28,
                        color: Color(0xFF5A5551),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tr('tns.fingerActivateSubtext'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel(l10n.tr('tns.email')),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _emailController,
                      hint: l10n.tr('tns.enterEmail'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(l10n.tr('tns.passowrd')),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _passwordController,
                      hint: l10n.tr('tns.enterPassword'),
                      obscureText: _isPasswordHidden,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _isPasswordHidden = !_isPasswordHidden,
                        ),
                        child: Icon(
                          _isPasswordHidden
                              ? SelectNetworkIcons.eyeDisabled
                              : SelectNetworkIcons.eye,
                          size: 20,
                          color: const Color(0xFF9A9A9A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _termsAccepted = !_termsAccepted),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _termsAccepted,
                              onChanged: (v) =>
                                  setState(() => _termsAccepted = v ?? false),
                              activeColor: AppColors.primaryRed,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.tr('tns.iagreewiththetermandconditions'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 14,
                                color: Color(0xFF5A5551),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canSubmit ? _onContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    disabledBackgroundColor: const Color(0xFFEFB8BD),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppFormTokens.buttonRadius),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          l10n.tr('tns.continue').toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Calibri',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
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
      text,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 12,
        color: Color(0xFF808080),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Calibri',
          color: Color(0xFFA6A6A6),
          fontSize: 16,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
