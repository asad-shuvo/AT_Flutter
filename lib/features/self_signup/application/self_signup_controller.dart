import 'dart:async';

import 'package:filip_at_flutter/features/self_signup/data/models/signup_session.dart';
import 'package:filip_at_flutter/features/self_signup/data/self_signup_repository.dart';
import 'package:flutter/foundation.dart';

enum SelfSignupView {
  emailInput,
  emailOtp,
  phoneInput,
  phoneOtp,
  captchaView,
  fullForm,
  passwordSet,
  success,
  failed,
}

enum CaptchaTarget { email, phone }

class SelfSignupController extends ChangeNotifier {
  SelfSignupController({required this.repository});

  final SelfSignupRepository repository;
  final SignupSession session = SignupSession();

  SelfSignupView view = SelfSignupView.emailInput;
  CaptchaTarget captchaTarget = CaptchaTarget.email;
  String language = 'de-DE';

  // Captcha state
  String captchaId = '';
  String captchaImageBase64 = '';
  bool isCaptchaLoading = false;
  bool isCaptchaInvalid = false;

  // OTP timer
  int otpSecondsLeft = 60;
  Timer? _otpTimer;

  // Loading / error state
  bool isLoading = false;
  String? errorMessage;

  // Step indicator (1=email steps, 2=phone/form steps)
  int get currentStep {
    switch (view) {
      case SelfSignupView.emailInput:
      case SelfSignupView.emailOtp:
        return 1;
      case SelfSignupView.captchaView:
        return captchaTarget == CaptchaTarget.email ? 1 : 2;
      case SelfSignupView.phoneInput:
      case SelfSignupView.phoneOtp:
        return 2;
      default:
        return 3;
    }
  }

  void setLanguageCode(String languageCode) {
    language = languageCode == 'de' ? 'de-DE' : 'en-US';
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  // ── Captcha ──────────────────────────────────────────────────────────────

  Future<void> loadCaptcha() async {
    isCaptchaLoading = true;
    isCaptchaInvalid = false;
    notifyListeners();
    try {
      await repository.fetchAnonymousToken();
      final result = await repository.createCaptcha();
      captchaId = result.id;
      captchaImageBase64 = result.imageBase64;
    } catch (_) {
      errorMessage = 'SOMETHING_WENT_WRONG';
    } finally {
      isCaptchaLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitCaptchaAndProceed(String captchaValue) async {
    isLoading = true;
    isCaptchaInvalid = false;
    notifyListeners();
    try {
      final res = await repository.submitCaptcha(captchaId, captchaValue);
      if (!res.isMatched) {
        isCaptchaInvalid = true;
        isLoading = false;
        notifyListeners();
        return false;
      }
      session.captchaVerificationCode = res.verificationCode;
      return true;
    } catch (_) {
      errorMessage = 'tns.captchaNotMatchError';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Email step ───────────────────────────────────────────────────────────

  Future<void> sendEmailCode(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      session.userEmail = email.trim();
      await repository.sendEmailVerificationCode(
        email: session.userEmail,
        captchaVerificationCode: session.captchaVerificationCode,
        language: language,
      );
      _startOtpTimer();
      view = SelfSignupView.emailOtp;
    } on SelfSignupException catch (e) {
      errorMessage = _mapError(e.code);
    } catch (_) {
      errorMessage = 'SOMETHING_WENT_WRONG';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyEmailCode(String code) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.verifyEmailVerificationCode(code);
      view = SelfSignupView.phoneInput;
      await loadCaptcha();
    } on SelfSignupException catch (e) {
      if (e.code == 'USER_EXIST_FOR_THIS_EMAIL') {
        errorMessage = 'tns.emailAlreadyTaken';
      } else {
        errorMessage = _mapError(e.code);
      }
    } catch (_) {
      errorMessage = 'SOMETHING_WENT_WRONG';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Phone step ───────────────────────────────────────────────────────────

  Future<void> sendPhoneCode(String phone) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      session.userPhoneNumber = phone;
      await repository.sendPhoneVerificationCode(
        phoneNumber: phone,
        captchaVerificationCode: session.captchaVerificationCode,
        language: language,
      );
      _startOtpTimer();
      view = SelfSignupView.phoneOtp;
    } on SelfSignupException catch (e) {
      errorMessage = _mapError(e.code);
    } catch (_) {
      errorMessage = 'SOMETHING_WENT_WRONG';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPhoneCode(String code) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.verifyPhoneVerificationCode(code);
      final isAvailable = await repository.getSignupVerificationData();
      session.isEmailAvailableForSelfSignup = isAvailable;
      view = isAvailable ? SelfSignupView.fullForm : SelfSignupView.passwordSet;
    } on SelfSignupException catch (e) {
      errorMessage = _mapError(e.code);
    } catch (_) {
      errorMessage = 'SOMETHING_WENT_WRONG';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Resend via captcha ───────────────────────────────────────────────────

  void showResendCaptcha(CaptchaTarget target) {
    captchaTarget = target;
    loadCaptcha();
    view = SelfSignupView.captchaView;
    notifyListeners();
  }

  Future<void> onResendCaptchaSubmit(String captchaValue) async {
    final ok = await submitCaptchaAndProceed(captchaValue);
    if (!ok) return;
    isLoading = true;
    notifyListeners();
    try {
      if (captchaTarget == CaptchaTarget.email) {
        await repository.resendEmailVerificationCode(
          captchaVerificationCode: session.captchaVerificationCode,
          language: language,
        );
        _startOtpTimer();
        view = SelfSignupView.emailOtp;
      } else {
        await repository.resendPhoneVerificationCode(
          captchaVerificationCode: session.captchaVerificationCode,
          language: language,
        );
        _startOtpTimer();
        view = SelfSignupView.phoneOtp;
      }
    } on SelfSignupException catch (e) {
      errorMessage = _mapError(e.code);
    } catch (_) {
      errorMessage = 'SOMETHING_WENT_WRONG';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Full form submit (Path A) ─────────────────────────────────────────────

  Future<void> submitFullForm({
    required String salutation,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String sex,
    required String street,
    required String city,
    required String postalCode,
    required String country,
    required String nationality,
    required String password,
    String postNominalTitle = '',
    String designation = '',
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.selfSignup(
        password: password,
        salutation: salutation,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        sex: sex,
        street: street,
        city: city,
        postalCode: postalCode,
        country: country,
        nationality: nationality,
        postNominalTitle: postNominalTitle,
        designation: designation,
      );
      view = SelfSignupView.success;
    } on SelfSignupException {
      view = SelfSignupView.failed;
    } catch (_) {
      view = SelfSignupView.failed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Password-only submit (Path B) ────────────────────────────────────────

  Future<void> submitPasswordSet({
    required String password,
    required String dateOfBirth,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.onboardUser(
        password: password,
        dateOfBirth: dateOfBirth,
      );
      view = SelfSignupView.success;
    } on SelfSignupException {
      view = SelfSignupView.failed;
    } catch (_) {
      view = SelfSignupView.failed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── OTP timer ────────────────────────────────────────────────────────────

  void _startOtpTimer() {
    _otpTimer?.cancel();
    otpSecondsLeft = 60;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (otpSecondsLeft > 0) {
        otpSecondsLeft--;
        notifyListeners();
      } else {
        t.cancel();
      }
    });
  }

  String get otpTimerLabel {
    final m = otpSecondsLeft ~/ 60;
    final s = otpSecondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')} SEC';
  }

  bool get canResend => otpSecondsLeft == 0;

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'EMAIL_VERIFICATION_CODE_INVALID':
      case 'EMAIL_VALIDATE_FAILED':
      case 'PHONE_VALIDATE_FAILED':
        return 'INVALID_VERIFICATION_CODE';
      case 'EMAIL_VERIFICATION_CODE_SEND_FAILED':
      case 'PHONE_VERIFICATION_CODE_SEND_FAILED':
        return 'FAILED_TO_SEND_VERIFICATION_CODE';
      case 'USER_EXIST_FOR_THIS_EMAIL':
        return 'tns.emailAlreadyTaken';
      default:
        return 'SOMETHING_WENT_WRONG';
    }
  }
}
