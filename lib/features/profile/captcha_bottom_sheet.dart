import 'dart:convert';

import 'package:filip_at_flutter/features/profile/contact_update_controller_base.dart';
import 'package:filip_at_flutter/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CaptchaBottomSheet extends StatefulWidget {
  const CaptchaBottomSheet({
    super.key,
    required this.controller,
    required this.onVerified,
  });

  final ContactUpdateControllerBase controller;
  final ValueChanged<String> onVerified;

  @override
  State<CaptchaBottomSheet> createState() => _CaptchaBottomSheetState();
}

class _CaptchaBottomSheetState extends State<CaptchaBottomSheet> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.prepareCaptcha();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _onVerifyTap() async {
    final value = _valueController.text.trim();
    if (value.isEmpty) return;
    final verificationCode = await widget.controller.verifyCaptcha(value);
    if (!mounted || verificationCode == null) return;
    Navigator.of(context).pop();
    widget.onVerified(verificationCode);
  }

  Future<void> _onRefreshTap() async {
    await widget.controller.prepareCaptcha();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final captcha = widget.controller.captcha;
        final isSubmitEnabled =
            _valueController.text.trim().isNotEmpty && !widget.controller.submitting;
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SafeArea(
            top: false,
            child: Container(
              height: 330,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth;
                  final captchaImageWidth = (contentWidth - 72).clamp(
                    180.0,
                    280.0,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: captchaImageWidth,
                                    child: SizedBox(
                                      height: 80,
                                      child: captcha != null
                                          ? Image.memory(
                                              base64Decode(captcha.imageBase64),
                                              fit: BoxFit.contain,
                                            )
                                          : const Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.primaryRed,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: widget.controller.captchaLoading
                                        ? null
                                        : _onRefreshTap,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    icon: const Icon(
                                      Icons.refresh,
                                      size: 24,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Text(
                                  'Captcha *',
                                  style: TextStyle(
                                    color: Color(0xFF808080),
                                    fontFamily: 'Calibri',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _valueController,
                                maxLength: 10,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                  fontFamily: 'Calibri',
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Captcha',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Calibri',
                                    color: Color(0xFFA6A6A6),
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC9C9C9),
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC9C9C9),
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryRed,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.controller.captchaError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  widget.controller.captchaError!,
                                  style: const TextStyle(
                                    fontFamily: 'Calibri',
                                    fontSize: 13,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          width: contentWidth * 0.9,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isSubmitEnabled ? _onVerifyTap : null,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primaryRed,
                              disabledBackgroundColor: const Color(0xFFD98C99),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'SUBMIT',
                              style: TextStyle(
                                fontFamily: 'Calibri',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
