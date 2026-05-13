import 'package:filip_at_flutter/features/profile/profile_models.dart';
import 'package:flutter/foundation.dart';

abstract class ContactUpdateControllerBase extends ChangeNotifier {
  CaptchaChallenge? get captcha;
  String? get captchaError;
  bool get captchaLoading;
  bool get submitting;
  String? get flowErrorCode;
  bool get timerRunning;
  String get countdownLabel;

  Future<void> prepareCaptcha();
  Future<String?> verifyCaptcha(String value);
}
