import 'package:filip_at_flutter/core/network/api_client.dart';

class SelfSignupException implements Exception {
  const SelfSignupException(this.code);
  final String code;
}

class CaptchaResult {
  const CaptchaResult({required this.id, required this.imageBase64});
  final String id;
  final String imageBase64;
}

class SelfSignupRepository {
  SelfSignupRepository({
    required this.apiClient,
    required this.signupServiceUrl,
    required this.captchaUrl,
    required this.originUrl,
    required this.tokenUrl,
  });

  final ApiClient apiClient;
  final String signupServiceUrl;
  final String captchaUrl;
  final String originUrl;
  final String tokenUrl;

  // Anonymous token fetched once via grant_type=authenticate_site before any
  // signup call. NativeScript's interceptor always picks up the stored token;
  // Flutter must fetch it explicitly since there is no interceptor.
  String _anonymousToken = '';

  Map<String, String> get _captchaHeaders => {
    'Origin': originUrl,
    if (_anonymousToken.isNotEmpty) 'Authorization': 'Bearer $_anonymousToken',
  };

  Map<String, String> get _signupHeaders => {
    'Origin': originUrl,
    if (_anonymousToken.isNotEmpty) 'Authorization': 'Bearer $_anonymousToken',
  };

  /// Call once per signup flow start (each "Create Now" press).
  /// Clears the cached token so the next [fetchAnonymousToken] call gets a
  /// fresh server session. Without this, a restarted flow reuses an expired
  /// token and hits 401.
  void resetSession() {
    _anonymousToken = '';
  }

  Future<void> fetchAnonymousToken() async {
    // Reuse existing token within a single signup session — server tracks
    // signup state (email verified, etc.) by session. Fetching a new token
    // mid-flow starts a new session and loses prior state.
    if (_anonymousToken.isNotEmpty) return;
    final result = await apiClient.postForm(
      url: tokenUrl,
      body: {'grant_type': 'authenticate_site'},
      headers: {'Origin': originUrl},
      suppressUnauthorizedHandling: true,
    );
    final body = result['body'] as Map<String, dynamic>;
    final token = body['access_token'] as String?;
    if (token != null && token.isNotEmpty) {
      _anonymousToken = token;
    }
  }

  Future<CaptchaResult> createCaptcha() async {
    final result = await apiClient.postJson(
      url: '${captchaUrl}CreateCaptcha',
      body: {},
      headers: _captchaHeaders,
    );
    final body = result['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors == null || errors['IsValid'] != true) {
      throw const SelfSignupException('CAPTCHA_CREATE_FAILED');
    }
    return CaptchaResult(
      id: body['Id'] as String? ?? '',
      imageBase64: body['Captcha'] as String? ?? '',
    );
  }

  Future<({bool isMatched, String verificationCode})> submitCaptcha(
    String id,
    String value,
  ) async {
    final result = await apiClient.postJson(
      url: '${captchaUrl}SubmitCaptcha',
      body: {'Id': id, 'Value': value},
      headers: _captchaHeaders,
    );
    final body = result['body'] as Map<String, dynamic>;
    final statusCode = body['StatusCode'] as int? ?? -1;
    final errors = body['ErrorMessages'] as List<dynamic>? ?? [];
    final verificationCode = body['VerificationCode'] as String? ?? '';
    final isMatched = statusCode == 0 && errors.isEmpty && verificationCode.isNotEmpty;
    return (isMatched: isMatched, verificationCode: verificationCode);
  }

  Future<void> sendEmailVerificationCode({
    required String email,
    required String captchaVerificationCode,
    String language = 'en-US',
  }) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/SendEmailVerificationCode',
      body: {
        'Email': email,
        'Language': language,
        'CaptchaVerificationCode': captchaVerificationCode,
      },
      headers: _signupHeaders,
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<void> resendEmailVerificationCode({
    required String captchaVerificationCode,
    String language = 'en-US',
  }) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/ResendEmailVerificationCode',
      body: {
        'Language': language,
        'CaptchaVerificationCode': captchaVerificationCode,
      },
      headers: _signupHeaders,
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<void> verifyEmailVerificationCode(String code) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/VerifyEmailVerificationCode',
      body: {
        'VerificationCode': code,
      },
      headers: _signupHeaders,
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required String captchaVerificationCode,
    String language = 'en-US',
  }) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/SendPhoneNumberVerificationCode',
      body: {
        'PhoneNumber': phoneNumber,
        'Language': language,
        'CaptchaVerificationCode': captchaVerificationCode,
      },
      headers: _signupHeaders,
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<void> resendPhoneVerificationCode({
    required String captchaVerificationCode,
    String language = 'en-US',
  }) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/ResendPhoneNumberVerificationCode',
      body: {
        'Language': language,
        'CaptchaVerificationCode': captchaVerificationCode,
      },
      headers: _signupHeaders,
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<void> verifyPhoneVerificationCode(String code) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/VerifyPhoneNumberVerificationCode',
      body: {
        'VerificationCode': code,
      },
      headers: _signupHeaders,
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<bool> getSignupVerificationData() async {
    final result = await apiClient.getJson(
      url: '${signupServiceUrl}SignupQuery/GetSignupVerificaitonData',
      headers: _signupHeaders,
    );
    final body = result['body'] as Map<String, dynamic>;
    if (body['Success'] != true) {
      throw const SelfSignupException('SOMETHING_WENT_WRONG');
    }
    final data = body['Data'] as Map<String, dynamic>? ?? {};
    return data['IsEmailAvailableForSelfSignup'] as bool? ?? true;
  }

  Future<void> selfSignup({
    required String password,
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
    String postNominalTitle = '',
    String designation = '',
  }) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/SelfSignup',
      headers: _signupHeaders,
      body: {
        'Password': password,
        'Person': {
          'Salutation': salutation,
          'FirstName': firstName,
          'LastName': lastName,
          'Sex': sex,
          'PostNominalTitle': postNominalTitle,
          'Designation': designation,
          'Street': street,
          'PostalCode': postalCode,
          'City': city,
          'Country': country,
          'Nationality': nationality,
          'DateOfBirth': dateOfBirth,
          'TwoFactorEnabled': true,
        },
      },
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  Future<void> onboardUser({
    required String password,
    required String dateOfBirth,
  }) async {
    final result = await apiClient.postJson(
      url: '${signupServiceUrl}SignupCommand/Onboard',
      headers: _signupHeaders,
      body: {
        'Password': password,
        'Person': {
          'DateOfBirth': dateOfBirth,
          'TwoFactorEnabled': true,
        },
      },
    );
    _assertValid(result['body'] as Map<String, dynamic>);
  }

  void _assertValid(Map<String, dynamic> body) {
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors != null && errors['IsValid'] == true) return;
    final errorMessages = body['ErrorMessages'] as List<dynamic>? ?? [];
    if (errorMessages.isNotEmpty) {
      throw SelfSignupException(errorMessages.first as String);
    }
    throw const SelfSignupException('SOMETHING_WENT_WRONG');
  }
}
