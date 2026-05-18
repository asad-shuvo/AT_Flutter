import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ResetPinStage { changePin, confirmation }

class ResetPinBottomSheet extends StatefulWidget {
  const ResetPinBottomSheet({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<ResetPinBottomSheet> createState() => _ResetPinBottomSheetState();
}

class _ResetPinBottomSheetState extends State<ResetPinBottomSheet> {
  _ResetPinStage _stage = _ResetPinStage.changePin;

  final _pinController = TextEditingController();
  final _retypePinController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordHidden = true;
  bool _submitting = false;

  String _savedPin = '';
  String _savedRetypePin = '';

  @override
  void dispose() {
    _pinController.dispose();
    _retypePinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _pinValid =>
      _pinController.text.length == 4 &&
      _retypePinController.text.length == 4 &&
      _pinController.text == _retypePinController.text;

  bool get _pinMismatch =>
      _retypePinController.text.isNotEmpty &&
      _pinController.text.isNotEmpty &&
      _pinController.text != _retypePinController.text;

  static final _passwordStrengthRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[-_!*@#$,.;?§%^&+=/]).{6,300}$',
  );

  bool get _passwordStrong =>
      _passwordStrengthRegex.hasMatch(_passwordController.text);

  bool get _confirmValid =>
      _passwordController.text.isNotEmpty && _passwordStrong && !_submitting;

  void _onUpdate() {
    if (!_pinValid) return;
    _savedPin = _pinController.text;
    _savedRetypePin = _retypePinController.text;
    setState(() => _stage = _ResetPinStage.confirmation);
  }

  Future<void> _onConfirm() async {
    if (!_confirmValid) return;
    setState(() => _submitting = true);

    final l10n = context.l10n;
    try {
      final result = await widget.repository.resetPin(
        pin: _savedPin,
        retypePin: _savedRetypePin,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        await widget.repository.updateStoredPinIfBiometricEnabled(
          pin: _savedPin,
        );
        if (!mounted) return;
      }

      Navigator.of(context).pop();

      final msg = result.isSuccess
          ? l10n.tr('PIN_RESET_SUCCESSFUL')
          : result.errorCode == 'WRONG_PASSWORD'
              ? l10n.tr('WRONG_PASSWORD')
              : l10n.tr('SOMETHING_WENT_WRONG');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.tr('SOMETHING_WENT_WRONG'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _stage == _ResetPinStage.changePin
        ? _ChangePinSheet(
            pinController: _pinController,
            retypePinController: _retypePinController,
            pinMismatch: _pinMismatch,
            pinValid: _pinValid,
            onUpdate: _onUpdate,
            onChanged: () => setState(() {}),
          )
        : _ConfirmationSheet(
            passwordController: _passwordController,
            passwordHidden: _passwordHidden,
            confirmValid: _confirmValid,
            passwordStrong: _passwordStrong,
            submitting: _submitting,
            onToggleVisibility: () =>
                setState(() => _passwordHidden = !_passwordHidden),
            onConfirm: _onConfirm,
            onChanged: () => setState(() {}),
          );
  }
}

class _ChangePinSheet extends StatelessWidget {
  const _ChangePinSheet({
    required this.pinController,
    required this.retypePinController,
    required this.pinMismatch,
    required this.pinValid,
    required this.onUpdate,
    required this.onChanged,
  });

  final TextEditingController pinController;
  final TextEditingController retypePinController;
  final bool pinMismatch;
  final bool pinValid;
  final VoidCallback onUpdate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(FilipIcons.pin, size: 22, color: Color(0xFF808080)),
              const SizedBox(width: 8),
              Text(
                l10n.tr('tns.changePin'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _FieldLabel(l10n.tr('tns.newPin')),
          const SizedBox(height: 8),
          _PinField(
            controller: pinController,
            hint: l10n.tr('tns.enterPin'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 16),
          _FieldLabel(l10n.tr('tns.repeatPin')),
          const SizedBox(height: 8),
          _PinField(
            controller: retypePinController,
            hint: l10n.tr('tns.repeatPin'),
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            hasError: pinMismatch,
          ),
          if (pinMismatch) ...[
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
          const SizedBox(height: 24),
          _ActionButton(
            label: l10n.tr('tns.update').toUpperCase(),
            enabled: pinValid,
            submitting: false,
            onTap: onUpdate,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({
    required this.passwordController,
    required this.passwordHidden,
    required this.confirmValid,
    required this.passwordStrong,
    required this.submitting,
    required this.onToggleVisibility,
    required this.onConfirm,
    required this.onChanged,
  });

  final TextEditingController passwordController;
  final bool passwordHidden;
  final bool confirmValid;
  final bool passwordStrong;
  final bool submitting;
  final VoidCallback onToggleVisibility;
  final VoidCallback onConfirm;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 22, color: Color(0xFF808080)),
              const SizedBox(width: 8),
              Text(
                l10n.tr('tns.confirmation'),
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tr('tns.resetPinpasswordInstruction'),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _FieldLabel(l10n.tr('tns.password')),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: passwordHidden,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onConfirm(),
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 16,
              color: Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: l10n.tr('tns.enterPassword'),
              hintStyle: const TextStyle(
                fontFamily: 'Calibri',
                color: Color(0xFFA6A6A6),
                fontSize: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  passwordHidden ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF808080),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
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
                borderSide: const BorderSide(
                    color: AppColors.primaryRed, width: 1.2),
              ),
            ),
          ),
          if (passwordController.text.isNotEmpty && !passwordStrong) ...[
            const SizedBox(height: 4),
            Text(
              l10n.tr('tns.passwordFromatMsg'),
              style: const TextStyle(
                fontFamily: 'Calibri',
                fontSize: 13,
                color: AppColors.primaryRed,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _ActionButton(
            label: l10n.tr('tns.confirm').toUpperCase(),
            enabled: confirmValid,
            submitting: submitting,
            onTap: onConfirm,
          ),
          const SizedBox(height: 8),
        ],
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
              color: hasError
                  ? AppColors.primaryRed
                  : const Color(0xFFC9C9C9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: BorderSide(
              color: hasError
                  ? AppColors.primaryRed
                  : const Color(0xFFC9C9C9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
          borderSide: const BorderSide(
              color: AppColors.primaryRed, width: 1.2),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.submitting,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
        child: submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Calibri',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
