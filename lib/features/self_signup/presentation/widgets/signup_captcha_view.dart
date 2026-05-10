import 'dart:convert';

import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';

class SignupCaptchaView extends StatefulWidget {
  const SignupCaptchaView({super.key, required this.controller});
  final SelfSignupController controller;

  @override
  State<SignupCaptchaView> createState() => _SignupCaptchaViewState();
}

class _SignupCaptchaViewState extends State<SignupCaptchaView> {
  final _captchaController = TextEditingController();

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _captchaController.text.trim();
    if (value.isEmpty) return;
    await widget.controller.onResendCaptchaSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildIllustration(),
                const SizedBox(height: 20),
                const Text(
                  'Submit Captcha',
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontStyle: FontStyle.italic,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter the captcha code into the box to continue the process.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 14,
                    color: Color(0xFF7A7A7A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
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
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E7),
                            border: Border.all(
                              color: const Color(0xFFD0C080),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: c.captchaImageBase64.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    base64Decode(c.captchaImageBase64),
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: c.loadCaptcha,
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF555555),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                signupFieldLabel('Captcha *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _captchaController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(),
                  style: signupInputStyle,
                  decoration: signupInputDecoration('Enter Captcha'),
                ),
                if (c.isCaptchaInvalid) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Captcha code does not match. Please try again.',
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 12,
                        color: Color(0xFFD91F32),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        signupBottomButton(
          label: 'SUBMIT >',
          isEnabled: _captchaController.text.trim().isNotEmpty && !c.isLoading,
          isLoading: c.isLoading,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Image.network(
      'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/onboarding_captcha_img.png',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => const Icon(
        Icons.security,
        size: 80,
        color: Color(0xFFD91F32),
      ),
    );
  }
}
