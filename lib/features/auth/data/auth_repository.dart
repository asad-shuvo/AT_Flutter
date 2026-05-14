import 'dart:convert';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:filip_at_flutter/features/auth/data/auth_exception.dart';
import 'package:filip_at_flutter/features/auth/data/remember_me_info.dart';

class AuthRepository {
  const AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorageService,
  })  : _apiClient = apiClient,
        _secureStorageService = secureStorageService;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorageService;

  Future<bool> hasActiveSession() async {
    final token = await _secureStorageService.read(AppStorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> verify2faCode({
    required String code,
    required String token,
  }) async {
    final response = await _apiClient.postForm(
      url: _apiClient.tokenUrl,
      body: <String, String>{
        'grant_type': 'authenticate_two_factor_code',
        'two_factor_code': code,
        'two_factor_token': token,
      },
      headers: <String, String>{'Origin': _apiClient.originUrl},
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    final responseBody = response['body'] as Map<String, dynamic>;

    if (statusCode < 200 || statusCode >= 300) {
      throw _mapAuthException(responseBody);
    }

    final accessToken = responseBody['access_token'] as String?;
    final refreshToken = responseBody['refresh_token'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException(
        message: '2FA succeeded but no access token was returned.',
      );
    }

    await _secureStorageService.write(
      key: AppStorageKeys.accessToken,
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorageService.write(
        key: AppStorageKeys.refreshToken,
        value: refreshToken,
      );
    }

    final loginCount = await getLoginCount();
    await _secureStorageService.write(
      key: AppStorageKeys.loginCount,
      value: '${loginCount + 1}',
    );
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    await _ensureAnonymousSession();

    final anonymousAccessToken = await _secureStorageService.read(
      AppStorageKeys.anonymousAccessToken,
    );

    final response = await _apiClient.postForm(
      url: _apiClient.tokenUrl,
      body: <String, String>{
        'grant_type': 'password',
        'username': username,
        'password': password,
      },
      headers: <String, String>{
        'Origin': _apiClient.originUrl,
        if (anonymousAccessToken != null && anonymousAccessToken.isNotEmpty)
          'Authorization': 'bearer $anonymousAccessToken',
      },
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    final responseBody = response['body'] as Map<String, dynamic>;

    if (statusCode < 200 || statusCode >= 300) {
      throw _mapAuthException(responseBody);
    }

    final accessToken = responseBody['access_token'] as String?;
    final refreshToken = responseBody['refresh_token'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException(
        message: 'Login succeeded but no access token was returned.',
      );
    }

    await _secureStorageService.write(
      key: AppStorageKeys.accessToken,
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorageService.write(
        key: AppStorageKeys.refreshToken,
        value: refreshToken,
      );
    }

    final loginCount = await getLoginCount();
    await _secureStorageService.write(
      key: AppStorageKeys.loginCount,
      value: '${loginCount + 1}',
    );
  }

  Future<void> clearSession() async {
    try {
      await _logoutFromPlatform();
    } catch (_) {
      // Best-effort server logout: always clear the local session so users
      // are not stranded in an authenticated state on device.
    }
    await _secureStorageService.delete(AppStorageKeys.accessToken);
    await _secureStorageService.delete(AppStorageKeys.refreshToken);
    await _secureStorageService.delete(AppStorageKeys.userId);
    await _secureStorageService.delete(AppStorageKeys.customerId);
    await _secureStorageService.delete(AppStorageKeys.firebaseTopic);
    // Clear anonymous tokens so the next login flow re-fetches a fresh
    // anonymous session (mirrors NativeScript clearAllCacheData behavior).
    await _secureStorageService.delete(AppStorageKeys.anonymousAccessToken);
    await _secureStorageService.delete(AppStorageKeys.anonymousRefreshToken);
  }

  Future<void> clearSessionLocally() async {
    await _secureStorageService.delete(AppStorageKeys.accessToken);
    await _secureStorageService.delete(AppStorageKeys.refreshToken);
    await _secureStorageService.delete(AppStorageKeys.userId);
    await _secureStorageService.delete(AppStorageKeys.customerId);
    await _secureStorageService.delete(AppStorageKeys.firebaseTopic);
    await _secureStorageService.delete(AppStorageKeys.anonymousAccessToken);
    await _secureStorageService.delete(AppStorageKeys.anonymousRefreshToken);
  }

  /// Attempts a silent token refresh using the stored refresh token.
  /// Returns true if new tokens were saved, false if refresh failed.
  Future<bool> tryRefreshTokens() async {
    final refreshToken = await _secureStorageService.read(
      AppStorageKeys.refreshToken,
    );
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _apiClient.postForm(
        url: _apiClient.tokenUrl,
        body: <String, String>{
          'grant_type': 'refresh_token',
          'client_id': ApiClient.tenantId,
          'refresh_token': refreshToken,
        },
        headers: <String, String>{'Origin': _apiClient.originUrl},
        suppressUnauthorizedHandling: true,
      );

      final statusCode = response['statusCode'] as int? ?? 0;
      if (statusCode < 200 || statusCode >= 300) return false;

      final body = response['body'] as Map<String, dynamic>;
      final newAccessToken = body['access_token'] as String?;
      final newRefreshToken = body['refresh_token'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) return false;

      await _secureStorageService.write(
        key: AppStorageKeys.accessToken,
        value: newAccessToken,
      );
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorageService.write(
          key: AppStorageKeys.refreshToken,
          value: newRefreshToken,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _logoutFromPlatform() async {
    final accessToken = await _secureStorageService.read(
      AppStorageKeys.accessToken,
    );
    final refreshToken = await _secureStorageService.read(
      AppStorageKeys.refreshToken,
    );

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return;
    }

    final logoutUrl = _buildLogoutUrl();
    final response = await _apiClient.postJson(
      url: logoutUrl,
      body: <String, dynamic>{'RefreshToken': refreshToken},
      headers: <String, String>{
        'Authorization': 'bearer $accessToken',
        'Origin': _apiClient.originUrl,
      },
      suppressUnauthorizedHandling: true,
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    final responseBody = response['body'] as Map<String, dynamic>;
    final responseStatusCode = responseBody['StatusCode'];

    if (statusCode == 401) {
      return;
    }

    if (statusCode < 200 ||
        statusCode >= 300 ||
        responseStatusCode != null && responseStatusCode != 0) {
      throw AuthException(
        code: 'logout_failed',
        message: 'Unable to complete logout on the server.',
      );
    }
  }

  String _buildLogoutUrl() {
    final tokenUri = Uri.parse(_apiClient.tokenUrl);
    final segments = List<String>.from(tokenUri.pathSegments);
    if (segments.isNotEmpty && segments.last == 'token') {
      segments[segments.length - 1] = 'logout';
    } else {
      segments.add('logout');
    }
    return tokenUri.replace(pathSegments: segments).toString();
  }

  Future<RememberMeInfo> getRememberMeInfo() async {
    final storedValue = await _secureStorageService.read(AppStorageKeys.rememberMe);

    if (storedValue == null || storedValue.isEmpty) {
      final emptyInfo = const RememberMeInfo.empty();
      await _secureStorageService.write(
        key: AppStorageKeys.rememberMe,
        value: jsonEncode(emptyInfo.toJson()),
      );
      return emptyInfo;
    }

    try {
      final decoded = jsonDecode(storedValue);
      if (decoded is Map<String, dynamic>) {
        return RememberMeInfo.fromJson(decoded);
      }
      if (decoded is Map) {
        return RememberMeInfo.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Fall back to a cleared remember-me state if legacy data is malformed.
    }

    await clearRememberMeInfo();
    return const RememberMeInfo.empty();
  }

  Future<void> saveRememberMeInfo({
    required String email,
    required String password,
  }) async {
    final rememberMeInfo = RememberMeInfo(
      isEnabled: true,
      email: email,
      password: password,
    );
    await _secureStorageService.write(
      key: AppStorageKeys.rememberMe,
      value: jsonEncode(rememberMeInfo.toJson()),
    );
  }

  Future<void> clearRememberMeInfo() async {
    await _secureStorageService.write(
      key: AppStorageKeys.rememberMe,
      value: jsonEncode(const RememberMeInfo.empty().toJson()),
    );
  }

  Future<int> getLoginCount() async {
    final storedValue = await _secureStorageService.read(AppStorageKeys.loginCount);
    if (storedValue == null || storedValue.isEmpty) {
      return 0;
    }

    return int.tryParse(storedValue) ?? 0;
  }

  Future<void> _ensureAnonymousSession() async {
    final anonymousAccessToken = await _secureStorageService.read(
      AppStorageKeys.anonymousAccessToken,
    );
    final anonymousRefreshToken = await _secureStorageService.read(
      AppStorageKeys.anonymousRefreshToken,
    );

    if ((anonymousAccessToken?.isNotEmpty ?? false) &&
        (anonymousRefreshToken?.isNotEmpty ?? false)) {
      return;
    }

    final response = await _apiClient.postForm(
      url: _apiClient.tokenUrl,
      body: const <String, String>{
        'grant_type': 'authenticate_site',
      },
      headers: <String, String>{
        'Origin': _apiClient.originUrl,
      },
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    final responseBody = response['body'] as Map<String, dynamic>;

    if (statusCode < 200 || statusCode >= 300) {
      throw const AuthException(
        message: 'Unable to initialize the stage login session.',
      );
    }

    final accessToken = responseBody['access_token'] as String?;
    final refreshToken = responseBody['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw const AuthException(
        message: 'The stage login bootstrap token response was incomplete.',
      );
    }

    await _secureStorageService.write(
      key: AppStorageKeys.anonymousAccessToken,
      value: accessToken,
    );
    await _secureStorageService.write(
      key: AppStorageKeys.anonymousRefreshToken,
      value: refreshToken,
    );
  }

  AuthException _mapAuthException(Map<String, dynamic> responseBody) {
    final code = responseBody['error'] as String?;
    final description = responseBody['error_description'] as String?;

    switch (code) {
      case 'incorrect_user_name_or_password':
        return const AuthException(
          code: 'incorrect_user_name_or_password',
          message: 'Incorrect email or password.',
        );
      case 'invalid_two_factor_code':
        return const AuthException(
          code: 'invalid_two_factor_code',
          message: 'Invalid Two Factor Code!!',
        );
      case 'invalid_two_factor_token':
        return const AuthException(
          code: 'invalid_two_factor_token',
          message: 'Invalid Two Factor Token!!',
        );
      case 'two_factor_code_require':
        return AuthException(
          code: code,
          description: description,
          message: 'Two-factor verification is required for this account.',
        );
      case 'persona_require':
        return AuthException(
          code: code,
          description: description,
          message: 'Persona selection is required before login can continue.',
        );
      case 'term_and_condition_acceptance_require':
        return AuthException(
          code: code,
          description: description,
          message: 'Terms and conditions must be accepted before login.',
        );
      case 'Session_Lock_Id':
        return const AuthException(
          code: 'Session_Lock_Id',
          message: 'This session is locked. Please try again later.',
        );
      default:
        return AuthException(
          code: code,
          description: description,
          message: 'Sign in failed. Please try again.',
        );
    }
  }
}
