import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/features/settings/application/biometric_service.dart';
import 'package:filip_at_flutter/features/settings/presentation/biometric_confirm_bottom_sheet.dart';
import 'package:filip_at_flutter/features/settings/presentation/biometric_not_enrolled_dialog.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetPinPage extends StatefulWidget {
  const SetPinPage({
    super.key,
    required this.repository,
    required this.biometricService,
  });

  final ProfileRepository repository;
  final BiometricService biometricService;

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final _pinController = TextEditingController();
  final _repeatPinController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _repeatPinController.dispose();
    super.dispose();
  }

  bool get _pinValid =>
      _pinController.text.length == 4 &&
      _repeatPinController.text.length == 4 &&
      _pinController.text == _repeatPinController.text;

  Future<void> _showNotEnrolledDialog() =>
      BiometricNotEnrolledDialog.show(context);

  bool get _pinMismatch =>
      _repeatPinController.text.isNotEmpty &&
      _pinController.text.isNotEmpty &&
      _pinController.text != _repeatPinController.text;

  Future<void> _onActivate() async {
    if (!_pinValid || _submitting) return;
    setState(() => _submitting = true);

    final l10n = context.l10n;

    try {
      final result = await widget.repository.setPin(
        pin: _pinController.text,
        retypePin: _repeatPinController.text,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.tr('SOMETHING_WENT_WRONG'))),
          );
        return;
      }

      setState(() => _submitting = false);
      final confirmed = await BiometricConfirmBottomSheet.show(
        context,
        icon: SelectNetworkIcons.faceScan,
        message: l10n.tr('tns.biometrincEnableInstruction'),
      );

      if (!mounted) return;

      if (!confirmed) {
        Navigator.of(context).pop(false);
        return;
      }

      final authStatus = await widget.biometricService.authenticate(
        reason: l10n.tr('tns.fingerprintAuthentication'),
      );

      if (!mounted) return;

      if (authStatus == BiometricAuthStatus.notEnrolled) {
        await _showNotEnrolledDialog();
        if (!mounted) return;
        Navigator.of(context).pop(false);
        return;
      }

      if (authStatus == BiometricAuthStatus.success) {
        await widget.repository.storePinCredential(pin: _pinController.text);
        if (!mounted) return;
      }

      Navigator.of(context).pop(authStatus == BiometricAuthStatus.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.tr('SOMETHING_WENT_WRONG'))),
        );
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
                        'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/recovery_pin.png',
                        width: 165,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.lock_outline,
                          size: 100,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('tns.setpin'),
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
                      l10n.tr('tns.pininstructionFinger'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _FieldLabel(l10n.tr('tns.pin')),
                    const SizedBox(height: 8),
                    _PinField(
                      controller: _pinController,
                      hint: l10n.tr('tns.enterpin'),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(l10n.tr('tns.repeatpin')),
                    const SizedBox(height: 8),
                    _PinField(
                      controller: _repeatPinController,
                      hint: l10n.tr('tns.repeatpin'),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      hasError: _pinMismatch,
                    ),
                    if (_pinMismatch) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.tr('tns.retypePinDoesntMatchMsg'),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 13,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
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
                  onPressed: (_pinValid && !_submitting) ? _onActivate : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    disabledBackgroundColor: const Color(0xFFD3D3D3),
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
                          l10n.tr('tns.tapToActivate').toUpperCase(),
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

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.hint,
    required this.textInputAction,
    required this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Calibri',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(
          fontFamily: 'Calibri',
          color: Color(0xFFA6A6A6),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide:
              const BorderSide(color: AppColors.primaryRed, width: 1.2),
        ),
      ),
    );
  }
}
