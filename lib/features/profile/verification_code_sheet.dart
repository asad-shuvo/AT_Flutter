import 'package:filip_at_flutter/features/profile/contact_update_controller_base.dart';
import 'package:filip_at_flutter/app/localization/app_localizations.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:filip_at_flutter/shared/theme/form_tokens.dart';

class VerificationCodeSheet extends StatefulWidget {
  const VerificationCodeSheet({
    super.key,
    required this.controller,
    required this.title,
    required this.icon,
    required this.descriptionText,
    required this.onConfirm,
    required this.onResend,
  });

  final ContactUpdateControllerBase controller;
  final String title;
  final IconData icon;
  final String descriptionText;
  final ValueChanged<String> onConfirm;
  final VoidCallback onResend;

  @override
  State<VerificationCodeSheet> createState() => _VerificationCodeSheetState();
}

class _VerificationCodeSheetState extends State<VerificationCodeSheet> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onConfirmTap() {
    final code = _codeController.text.trim();
    if (code.length != 4) return;
    widget.onConfirm(code);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final timerRunning = widget.controller.timerRunning;
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SafeArea(
            top: false,
            child: Container(
              height: 500,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
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
                                widget.icon,
                                size: 26,
                                color: const Color(0xFF808080),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.descriptionText,
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF808080),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            context.l10n.tr('tns.verificationCode'),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 12,
                              color: Color(0xFF808080),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _onConfirmTap(),
                            style: const TextStyle(
                              fontFamily: 'Calibri',
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Color(0xFF808080),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: context.l10n.tr('tns.verificationCode'),
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
                                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E2D3A),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E2D3A),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E2D3A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                context.l10n.tr('tns.timeLeft'),
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 20 / 1.2,
                                  color: Color(0xFF808080),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.controller.countdownLabel,
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 20 / 1.2,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: timerRunning
                                      ? const Color(0xFFD9D9D9)
                                      : AppColors.primaryRed,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: TextButton.icon(
                                  onPressed: timerRunning ? null : widget.onResend,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: timerRunning
                                        ? const Color(0xFF333333)
                                        : Colors.white,
                                    size: 24,
                                  ),
                                  label: Text(
                                    'RESEND NOW',
                                    style: TextStyle(
                                      fontFamily: 'Calibri',
                                      fontSize: 17 / 1.2,
                                      color: timerRunning
                                          ? const Color(0xFF333333)
                                          : Colors.white,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: timerRunning
                                        ? const Color(0xFF333333)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.controller.flowErrorCode != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.controller.flowErrorCode!,
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC9C9C9)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: widget.controller.submitting
                                ? null
                                : _onConfirmTap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primaryRed,
                              disabledBackgroundColor: const Color(0xFFE39CA6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppFormTokens.fieldRadius),
                              ),
                            ),
                            child: Text(
                              context.l10n.tr('tns.confirm'),
                              style: const TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

