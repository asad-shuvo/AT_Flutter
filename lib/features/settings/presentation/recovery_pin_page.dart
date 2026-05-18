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

class RecoveryPinPage extends StatefulWidget {
  const RecoveryPinPage({
    super.key,
    required this.repository,
    required this.biometricService,
  });

  final ProfileRepository repository;
  final BiometricService biometricService;

  @override
  State<RecoveryPinPage> createState() => _RecoveryPinPageState();
}

class _RecoveryPinPageState extends State<RecoveryPinPage> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _pinReady => _pinController.text.length == 4 && !_submitting;

  Future<void> _onProceed() async {
    if (!_pinReady) return;
    setState(() => _submitting = true);

    final l10n = context.l10n;
    try {
      final result = await widget.repository.verifyPinForBiometric(
        pin: _pinController.text,
      );

      if (!mounted) return;

      if (!result.isSuccess) {
        setState(() => _submitting = false);
        final msg = result.errorCode == 'incorrect_user_name_or_pin'
            ? l10n.tr('tns.incorrectUserNameOrPin')
            : l10n.tr('SOMETHING_WENT_WRONG');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
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
        await BiometricNotEnrolledDialog.show(context);
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
          SnackBar(
            content: Text(context.l10n.tr('SOMETHING_WENT_WRONG')),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pin = _pinController.text;

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
                      l10n.tr('tns.recoverypincode'),
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
                      l10n.tr('tns.enterpincode'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 16,
                        height: 1.4,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    const SizedBox(height: 36),
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: _PinOtpRow(
                        pin: pin,
                        onTap: () => _focusNode.requestFocus(),
                      ),
                    ),
                    // Hidden text field captures input
                    SizedBox(
                      height: 0,
                      child: TextField(
                        controller: _pinController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 1,
                        ),
                        cursorColor: Colors.transparent,
                        cursorWidth: 0,
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
                  onPressed: _pinReady ? _onProceed : null,
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
                          l10n.tr('tns.proceed').toUpperCase(),
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

class _PinOtpRow extends StatelessWidget {
  const _PinOtpRow({required this.pin, required this.onTap});

  final String pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < pin.length;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
              border: Border.all(
                color: filled
                    ? AppColors.primaryRed
                    : const Color(0xFFC9C9C9),
                width: filled ? 1.4 : 1.0,
              ),
            ),
            child: Center(
              child: filled
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF333333),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
