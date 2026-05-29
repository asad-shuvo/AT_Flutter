import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/features/profile/update_password_controller.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class UpdatePasswordForm extends StatefulWidget {
  const UpdatePasswordForm({
    super.key,
    required this.controller,
    required this.onConfirm,
  });

  final UpdatePasswordController controller;
  final void Function(String oldPassword, String newPassword) onConfirm;

  @override
  State<UpdatePasswordForm> createState() => _UpdatePasswordFormState();
}

class _UpdatePasswordFormState extends State<UpdatePasswordForm> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showRepeat = false;

  String? _currentError;
  String? _newError;
  String? _repeatError;
  final RegExp _passwordStrengthRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{6,}$',
  );

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    final current = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final repeat = _repeatPasswordController.text;

    String? currentErr;
    String? newErr;
    String? repeatErr;

    if (current.isEmpty) {
      currentErr = l10n.tr('tns.enterCurrentPassword');
    } else if (!_passwordStrengthRegex.hasMatch(current)) {
      currentErr = l10n.tr('tns.newPasswordErrMessage');
    }
    if (newPw.isEmpty) {
      newErr = l10n.tr('tns.enterNewPassword');
    } else if (!_passwordStrengthRegex.hasMatch(newPw)) {
      newErr = l10n.tr('tns.newPasswordErrMessage');
    }
    if (repeat.isEmpty) {
      repeatErr = l10n.tr('tns.repeatNewPassword');
    } else if (newPw != repeat) {
      repeatErr = l10n.tr('tns.confirmPasswordErrMessage');
    }

    setState(() {
      _currentError = currentErr;
      _newError = newErr;
      _repeatError = repeatErr;
    });

    return currentErr == null && newErr == null && repeatErr == null;
  }

  void _onConfirmTap() {
    final l10n = context.l10n;
    if (!_validate(l10n)) return;
    Navigator.of(context).pop();
    widget.onConfirm(
      _currentPasswordController.text,
      _newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasAllFields =
        _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _repeatPasswordController.text.isNotEmpty;
    final isEnabled = hasAllFields && !widget.controller.submitting;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.vpn_key_outlined,
                              color: Color(0xFF808080),
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.tr('tns.changePassword'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 22 / 1.2,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        signupFieldLabel(l10n.tr('tns.currentPassword')),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _currentPasswordController,
                          hint: l10n.tr('tns.enterCurrentPassword'),
                          showPassword: _showCurrent,
                          onToggle: () =>
                              setState(() => _showCurrent = !_showCurrent),
                          onChanged: (_) =>
                              setState(() => _currentError = null),
                          textInputAction: TextInputAction.next,
                          error: _currentError,
                        ),
                        const SizedBox(height: 16),
                        signupFieldLabel(l10n.tr('tns.newPassword')),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _newPasswordController,
                          hint: l10n.tr('tns.enterNewPassword'),
                          showPassword: _showNew,
                          onToggle: () =>
                              setState(() => _showNew = !_showNew),
                          onChanged: (_) =>
                              setState(() => _newError = null),
                          textInputAction: TextInputAction.next,
                          error: _newError,
                        ),
                        const SizedBox(height: 16),
                        signupFieldLabel(l10n.tr('tns.repeatNewPassword')),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _repeatPasswordController,
                          hint: l10n.tr('tns.repeatNewPassword'),
                          showPassword: _showRepeat,
                          onToggle: () =>
                              setState(() => _showRepeat = !_showRepeat),
                          onChanged: (_) =>
                              setState(() => _repeatError = null),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onConfirmTap(),
                          error: _repeatError,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isEnabled ? _onConfirmTap : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryRed,
                        disabledBackgroundColor: const Color(0xFFE39CA6),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: Text(
                        l10n.tr('tns.update'),
                        style: const TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.showPassword,
    required this.onToggle,
    required this.onChanged,
    required this.textInputAction,
    this.onSubmitted,
    this.error,
  });

  final TextEditingController controller;
  final String hint;
  final bool showPassword;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: !showPassword,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: signupInputStyle,
          decoration: signupInputDecoration(hint).copyWith(
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                showPassword
                    ? SelectNetworkIcons.eye
                    : SelectNetworkIcons.eyeDisabled,
                size: 20,
                color: const Color(0xFF888888),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(
              fontFamily: 'Calibri',
              fontSize: 13,
              color: AppColors.primaryRed,
            ),
          ),
        ],
      ],
    );
  }
}
