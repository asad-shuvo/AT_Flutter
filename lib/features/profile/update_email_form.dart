import 'package:filip_at_flutter/features/profile/update_email_controller.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/icons/app_icon_packs.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class UpdateEmailForm extends StatefulWidget {
  const UpdateEmailForm({
    super.key,
    required this.controller,
    required this.currentEmail,
    required this.onConfirm,
  });

  final UpdateEmailController controller;
  final String currentEmail;
  final ValueChanged<String> onConfirm;

  @override
  State<UpdateEmailForm> createState() => _UpdateEmailFormState();
}

class _UpdateEmailFormState extends State<UpdateEmailForm> {
  final TextEditingController _emailController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(value);
  }

  void _onConfirmTap() {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _localError = l10n.tr('account.emailRequired'));
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _localError = l10n.tr('account.emailInvalid'));
      return;
    }
    if (email == widget.currentEmail) {
      setState(() => _localError = l10n.tr('account.emailUnchanged'));
      return;
    }
    setState(() => _localError = null);
    Navigator.of(context).pop();
    widget.onConfirm(email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isUpdateEnabled =
        _emailController.text.trim().isNotEmpty && !widget.controller.submitting;

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
              height: 430,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                SelectNetworkIcons.email,
                                color: Color(0xFF808080),
                                size: 26,
                              ),
                              SizedBox(width: 10),
                              Text(
                                l10n.tr('account.changeEmailAddress'),
                                style: TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            l10n.tr('account.updateEmailSubHeader'),
                            style: TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF808080),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            l10n.tr('account.newEmailAddress'),
                            style: TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 12,
                              color: Color(0xFF808080),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() => _localError = null),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF808080),
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.tr('account.enterNewEmailAddress'),
                              hintStyle: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 16,
                                color: Color(0xFFABABAB),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 17,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E2D3A),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E2D3A),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E2D3A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (_localError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _localError!,
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 14,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isUpdateEnabled ? _onConfirmTap : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primaryRed,
                        disabledBackgroundColor: const Color(0xFFE39CA6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'UPDATE',
                        style: TextStyle(
                          fontFamily: 'Calibri',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
