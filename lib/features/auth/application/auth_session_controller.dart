import 'package:filip_at_flutter/features/auth/application/auth_session_state.dart';
import 'package:filip_at_flutter/features/auth/data/auth_repository.dart';
import 'package:filip_at_flutter/features/auth/data/remember_me_info.dart';
import 'package:flutter/foundation.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  AuthSessionState _state = AuthSessionState.unknown();
  bool _hasCompletedFirstLogin = false;

  AuthSessionState get state => _state;

  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  bool get hasCompletedFirstLogin => _hasCompletedFirstLogin;

  Future<void> restoreSession() async {
    // Match the requested mobile behavior: reopening or clearing the app
    // should always return the user to the login screen, while remembered
    // credentials remain available separately.
    _hasCompletedFirstLogin = await _authRepository.getLoginCount() >= 1;
    await _authRepository.clearSession();
    _state = AuthSessionState.unauthenticated();
    notifyListeners();
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      await _authRepository.signIn(
        username: username,
        password: password,
      );
      _hasCompletedFirstLogin = true;
      _state = AuthSessionState.authenticated();
      notifyListeners();
    } catch (_) {
      _state = AuthSessionState.unauthenticated();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verify2faCode({
    required String code,
    required String token,
  }) async {
    try {
      await _authRepository.verify2faCode(code: code, token: token);
      _hasCompletedFirstLogin = true;
      _state = AuthSessionState.authenticated();
      notifyListeners();
    } catch (_) {
      _state = AuthSessionState.unauthenticated();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authRepository.clearSession();
    _state = AuthSessionState.unauthenticated();
    notifyListeners();
  }

  Future<void> expireSession() async {
    await _authRepository.clearSessionLocally();
    _state = AuthSessionState.unauthenticated();
    notifyListeners();
  }

  Future<bool> tryRefreshTokens() {
    return _authRepository.tryRefreshTokens();
  }

  Future<RememberMeInfo> getRememberMeInfo() {
    return _authRepository.getRememberMeInfo();
  }

  Future<void> saveRememberMeInfo({
    required String email,
    required String password,
  }) {
    return _authRepository.saveRememberMeInfo(
      email: email,
      password: password,
    );
  }

  Future<void> clearRememberMeInfo() {
    return _authRepository.clearRememberMeInfo();
  }
}
