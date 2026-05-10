import 'package:filip_at_flutter/features/self_signup/application/self_signup_controller.dart';
import 'package:filip_at_flutter/features/self_signup/presentation/widgets/signup_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupOtpStep extends StatefulWidget {
  const SignupOtpStep({
    super.key,
    required this.controller,
    required this.isEmail,
  });
  final SelfSignupController controller;
  final bool isEmail;

  @override
  State<SignupOtpStep> createState() => _SignupOtpStepState();
}

class _SignupOtpStepState extends State<SignupOtpStep> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) return;
    if (widget.isEmail) {
      await widget.controller.verifyEmailCode(code);
    } else {
      await widget.controller.verifyPhoneCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final maskedContact = widget.isEmail
        ? c.session.userEmail
        : c.session.userPhoneNumber;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                _buildIllustration(),
                const SizedBox(height: 12),
                Text(
                  widget.isEmail ? 'Email Verification' : 'Phone Number Verification',
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontStyle: FontStyle.italic,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter the 4 digit security code sent to your '
                  '${widget.isEmail ? 'email address' : 'mobile no.'} $maskedContact',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 14,
                    color: Color(0xFF7A7A7A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _verify(),
                  style: const TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFFC9C9C9),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFFD91F32),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'TIME LEFT  ',
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 13,
                        color: Color(0xFF8B8B8B),
                      ),
                    ),
                    Text(
                      c.otpTimerLabel,
                      style: const TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD91F32),
                      ),
                    ),
                    const Spacer(),
                    _buildResendButton(c),
                  ],
                ),
              ],
            ),
          ),
        ),
        signupBottomButton(
          label: widget.isEmail ? 'VERIFY >' : 'CONTINUE >',
          isEnabled: _otpController.text.trim().length == 4 && !c.isLoading,
          isLoading: c.isLoading,
          onTap: _verify,
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    final url = widget.isEmail
        ? 'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/onboarding_email.png'
        : 'https://az-cdn.selise.biz/selisecdn/cdn/slnetwork/assets/mobile_app_images/onboarding_phone.png';
    return Image.network(
      url,
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Icon(
        widget.isEmail ? Icons.mail_outline : Icons.phone_android,
        size: 80,
        color: const Color(0xFFD91F32),
      ),
    );
  }

  Widget _buildResendButton(SelfSignupController c) {
    final enabled = c.canResend;
    return GestureDetector(
      onTap: enabled
          ? () => c.showResendCaptcha(
                widget.isEmail ? CaptchaTarget.email : CaptchaTarget.phone,
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFD91F32) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: enabled ? Colors.white : const Color(0xFF888888),
            ),
            const SizedBox(width: 4),
            Text(
              'RESEND NOW',
              style: TextStyle(
                fontFamily: 'Calibri',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
