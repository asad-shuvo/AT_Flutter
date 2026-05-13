import 'dart:async';

import 'package:filip_at_flutter/features/profile/contact_update_controller_base.dart';
import 'package:filip_at_flutter/features/profile/profile_models.dart';
import 'package:filip_at_flutter/features/profile/profile_repository.dart';

class UpdateEmailController extends ContactUpdateControllerBase {
  UpdateEmailController({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  CaptchaChallenge? _captcha;
  String? _captchaError;
  bool _captchaLoading = false;

  String _newEmail = '';
  String _currentEmail = '';
  String _verificationToken = '';
  String? _flowErrorCode;

  int _secondsLeft = 180;
  bool _timerRunning = false;
  Timer? _timer;

  bool _submitting = false;

  @override
  CaptchaChallenge? get captcha => _captcha;
  @override
  String? get captchaError => _captchaError;
  @override
  bool get captchaLoading => _captchaLoading;
  @override
  bool get submitting => _submitting;
  @override
  String? get flowErrorCode => _flowErrorCode;
  String get newEmail => _newEmail;
  @override
  bool get timerRunning => _timerRunning;
  int get secondsLeft => _secondsLeft;
  @override
  String get countdownLabel {
    final min = _secondsLeft ~/ 60;
    final sec = _secondsLeft % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> prepareCaptcha() async {
    _captchaLoading = true;
    _captchaError = null;
    notifyListeners();

    try {
      _captcha = await _repository.getCaptcha();
    } catch (_) {
      _captchaError = 'CAPTCHA_CREATE_FAILED';
    } finally {
      _captchaLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<String?> verifyCaptcha(String value) async {
    final challenge = _captcha;
    if (challenge == null) return null;
    _captchaError = null;
    _submitting = true;
    notifyListeners();
    try {
      final result = await _repository.submitCaptcha(
        captchaId: challenge.id,
        value: value,
      );
      if (!result.isSuccess) {
        _captchaError = 'CAPTCHA_NOT_MATCHED';
        return null;
      }
      return result.verificationCode;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> startEmailFlow({
    required String currentEmail,
    required String newEmail,
    required String captchaVerificationCode,
    required String language,
  }) async {
    _flowErrorCode = null;
    _submitting = true;
    notifyListeners();
    try {
      _currentEmail = currentEmail;
      _newEmail = newEmail;
      final result = await _repository.startEmailVerification(
        newEmail: newEmail,
        captchaVerificationCode: captchaVerificationCode,
        language: language,
      );
      if (!result.isSuccess) {
        _flowErrorCode = result.errorCode ?? 'SOMETHING_WENT_WRONG';
        return false;
      }

      _verificationToken = result.token;
      _startTimer();
      return true;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerificationCode(String captchaVerificationCode) async {
    _flowErrorCode = null;
    _submitting = true;
    notifyListeners();
    try {
      final result = await _repository.resendVerificationCode(
        captchaVerificationCode: captchaVerificationCode,
        contactVerificationToken: _verificationToken,
      );
      if (!result.isSuccess) {
        _flowErrorCode = result.errorCode ?? 'SOMETHING_WENT_WRONG';
        return false;
      }

      _startTimer();
      return true;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> confirmVerificationCode(String code) async {
    _flowErrorCode = null;
    _submitting = true;
    notifyListeners();
    try {
      final result = await _repository.confirmEmailChange(
        verificationToken: _verificationToken,
        verificationCode: code,
        oldEmail: _currentEmail,
        newEmail: _newEmail,
      );

      if (!result.isSuccess) {
        _flowErrorCode = result.errorCode ?? 'SOMETHING_WENT_WRONG';
        return false;
      }

      _stopTimer();
      return true;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void resetFlow() {
    _captcha = null;
    _captchaError = null;
    _newEmail = '';
    _currentEmail = '';
    _verificationToken = '';
    _flowErrorCode = null;
    _submitting = false;
    _stopTimer(resetSeconds: true);
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 180;
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _stopTimer();
      } else {
        _secondsLeft -= 1;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _stopTimer({bool resetSeconds = false}) {
    _timer?.cancel();
    _timerRunning = false;
    if (resetSeconds) {
      _secondsLeft = 180;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
