import 'package:filip_at_flutter/core/network/api_client.dart';

class ForgotPasswordCaptcha {
  const ForgotPasswordCaptcha({required this.id, required this.imageBase64});
  final String id;
  final String imageBase64;
}

enum RecoverAccountResult { success, emailNotFound, captchaNotMatched, error }

class ForgotPasswordRepository {
  ForgotPasswordRepository({
    required ApiClient apiClient,
    required String captchaUrl,
    required String tokenUrl,
  })  : _apiClient = apiClient,
        _captchaUrl = captchaUrl,
        _tokenUrl = tokenUrl;

  final ApiClient _apiClient;
  final String _captchaUrl;
  final String _tokenUrl;

  // Anonymous session token — fetched once per flow start (same pattern as SelfSignupRepository).
  // NS HTTP interceptor adds this automatically; Flutter must fetch explicitly.
  String _anonymousToken = '';

  Map<String, String> get _headers => <String, String>{
        'Origin': _apiClient.originUrl,
        if (_anonymousToken.isNotEmpty) 'Authorization': 'Bearer $_anonymousToken',
      };

  Future<void> _ensureAnonymousToken() async {
    if (_anonymousToken.isNotEmpty) return;
    final result = await _apiClient.postForm(
      url: _tokenUrl,
      body: <String, String>{'grant_type': 'authenticate_site'},
      headers: <String, String>{'Origin': _apiClient.originUrl},
      suppressUnauthorizedHandling: true,
    );
    final body = result['body'] as Map<String, dynamic>;
    final token = body['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      _anonymousToken = token;
    }
  }

  /// Call this when starting a new forgot-password flow so the next captcha
  /// load gets a fresh anonymous session.
  void resetSession() {
    _anonymousToken = '';
  }

  Future<ForgotPasswordCaptcha> createCaptcha() async {
    await _ensureAnonymousToken();
    final response = await _apiClient.postJson(
      url: '${_captchaUrl}CreateCaptcha',
      body: <String, dynamic>{},
      headers: _headers,
    );
    final body = response['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors?['IsValid'] != true) {
      throw Exception('CAPTCHA_CREATE_FAILED');
    }
    return ForgotPasswordCaptcha(
      id: body['Id'] as String? ?? '',
      imageBase64: body['Captcha'] as String? ?? '',
    );
  }

  Future<({bool isMatched, String verificationCode})> submitCaptcha({
    required String captchaId,
    required String value,
  }) async {
    final response = await _apiClient.postJson(
      url: '${_captchaUrl}SubmitCaptcha',
      body: <String, dynamic>{'Id': captchaId, 'Value': value},
      headers: _headers,
    );
    final body = response['body'] as Map<String, dynamic>;
    final statusCode = body['StatusCode'] as int? ?? -1;
    final verificationCode = body['VerificationCode'] as String? ?? '';
    final errorMessages = List<dynamic>.from(
      (body['ErrorMessages'] as List<dynamic>?) ?? const <dynamic>[],
    );
    final isMatched =
        statusCode == 0 && errorMessages.isEmpty && verificationCode.isNotEmpty;
    return (isMatched: isMatched, verificationCode: verificationCode);
  }

  Future<RecoverAccountResult> recoverAccount({
    required String email,
    required String verificationCode,
  }) async {
    final response = await _apiClient.postJson(
      url: '${_securityBaseUrl}SecurityCommand/RecoverAccount',
      body: <String, dynamic>{
        'Email': email,
        'VerificationCode': verificationCode,
      },
      headers: _headers,
    );
    final statusCode = response['statusCode'] as int? ?? 0;
    final body = response['body'] as Map<String, dynamic>;

    if (statusCode < 200 || statusCode >= 300) {
      return RecoverAccountResult.error;
    }

    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors?['IsValid'] == true) {
      return RecoverAccountResult.success;
    }

    // NS EmailErrorMapping: Email_Not_Found → tns.emailNotFound
    final errorMessages = List<dynamic>.from(
      (body['ErrorMessages'] as List<dynamic>?) ?? const <dynamic>[],
    );
    final firstMessage =
        errorMessages.isNotEmpty ? errorMessages.first.toString() : '';

    final errorList = errors?['Errors'] as List<dynamic>? ?? const <dynamic>[];
    String firstCode = firstMessage;
    if (errorList.isNotEmpty) {
      final firstError = errorList.first;
      if (firstError is Map) {
        firstCode = firstError['ErrorMessage']?.toString() ?? firstMessage;
      }
    }

    if (firstCode == 'Email_Not_Found') {
      return RecoverAccountResult.emailNotFound;
    }
    return RecoverAccountResult.error;
  }

  // ─── Deep-link reset-password flow ────────────────────────────────────────

  /// Validates the activation code from the deep-link URL.
  /// NS: GET {Security}Authentication/ActivateAccountCodeCheck?ActivateAccountCode={code}
  /// Returns `recoverAccountCode` (to pass to [resetPasswordWithCode]) or null if invalid.
  Future<String?> checkActivationCode(String activationCode) async {
    await _ensureAnonymousToken();
    final url = Uri.parse(
      '${_securityBaseUrl}Authentication/ActivateAccountCodeCheck',
    ).replace(
      queryParameters: <String, String>{'ActivateAccountCode': activationCode},
    );
    final response = await _apiClient.getJson(
      url: url.toString(),
      headers: _headers,
    );
    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    final bodyStatusCode = body['StatusCode'] as int? ?? -1;
    final codeValid = body['CodeValid'] == true;
    if (bodyStatusCode == 0 && codeValid) {
      return body['RecoverAccountCode'] as String? ?? activationCode;
    }
    return null;
  }

  /// Resets the password using the recovery code from [checkActivationCode].
  /// NS: POST {Security}SecurityCommand/ResetPassword
  ///     Body: {NewPassword, RecoverAccountCode}
  Future<bool> resetPasswordWithCode({
    required String newPassword,
    required String recoverAccountCode,
  }) async {
    await _ensureAnonymousToken();
    final response = await _apiClient.postJson(
      url: '${_securityBaseUrl}SecurityCommand/ResetPassword',
      body: <String, dynamic>{
        'NewPassword': newPassword,
        'RecoverAccountCode': recoverAccountCode,
      },
      headers: _headers,
    );
    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'] as Map<String, dynamic>? ?? {};
    final errors = body['Errors'] as Map<String, dynamic>?;
    return errors?['IsValid'] == true;
  }

  String get _securityBaseUrl {
    final base = _apiClient.baseUrl;
    if (base.contains('seliselocal')) {
      return '$base/uam/v23/UserAccessManagement/';
    } else if (base.contains('selisestage')) {
      return '$base/uam/v33/UserAccessManagement/';
    } else if (base.contains('seliseuat')) {
      return '$base/uam/v33/UserAccessManagement/';
    } else {
      return '$base/uam/v100/UserAccessManagement/';
    }
  }
}
