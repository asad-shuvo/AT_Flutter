import 'package:local_auth/local_auth.dart';

enum BiometricAuthStatus { success, notEnrolled, unavailable, failed }

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> isHardwareSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<BiometricAuthStatus> authenticate({required String reason}) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return BiometricAuthStatus.unavailable;

      final enrolled = await _auth.canCheckBiometrics;
      if (!enrolled) return BiometricAuthStatus.notEnrolled;

      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok ? BiometricAuthStatus.success : BiometricAuthStatus.failed;
    } catch (_) {
      return BiometricAuthStatus.failed;
    }
  }
}
