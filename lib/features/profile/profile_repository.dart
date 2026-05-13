import 'dart:math';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/profile/profile_models.dart';

class ProfileRepository {
  const ProfileRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
    required String captchaUrl,
  }) : _apiClient = apiClient,
       _sessionCache = userSessionCache,
       _captchaUrl = captchaUrl;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;
  final String _captchaUrl;

  Future<CaptchaChallenge> getCaptcha() async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_captchaUrl}CreateCaptcha',
      body: <String, dynamic>{},
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors?['IsValid'] != true) {
      throw Exception('CAPTCHA_CREATE_FAILED');
    }

    return CaptchaChallenge(
      id: body['Id'] as String? ?? '',
      imageBase64: body['Captcha'] as String? ?? '',
    );
  }

  Future<({bool isSuccess, String verificationCode})> submitCaptcha({
    required String captchaId,
    required String value,
  }) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_captchaUrl}SubmitCaptcha',
      body: <String, dynamic>{'Id': captchaId, 'Value': value},
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final statusCode = body['StatusCode'] as int? ?? -1;
    final verificationCode = body['VerificationCode'] as String? ?? '';
    final errorMessages = List<String>.from(
      (body['ErrorMessages'] as List<dynamic>?) ?? const <dynamic>[],
    );

    final isSuccess =
        statusCode == 0 && errorMessages.isEmpty && verificationCode.isNotEmpty;
    return (isSuccess: isSuccess, verificationCode: verificationCode);
  }

  Future<VerifyPrimaryContactResult> startEmailVerification({
    required String newEmail,
    required String captchaVerificationCode,
    required String language,
  }) async {
    final headers = await _authorizedHeaders();
    await _requireUser();

    final existsResponse = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/IsUserExistForContact',
      body: <String, dynamic>{
        'ContactType': 'Email',
        'Contact': newEmail,
      },
      headers: headers,
    );

    final existsBody = existsResponse['body'] as Map<String, dynamic>;
    if (existsBody['UserExist'] == true) {
      return const VerifyPrimaryContactResult(
        isSuccess: false,
        token: '',
        errorCode: 'USER_EXISTS_WITH_NEW_CONTACT',
      );
    }

    final token = _newGuid();
    final verifyResponse = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/VerifyPrimaryContact',
      body: <String, dynamic>{
        'Token': token,
        'Contact': newEmail,
        'Language': language,
        'ContactType': 0,
        'TemplateName': 'UserEmailChangeVerificationByCustomer',
        'CaptchaString': captchaVerificationCode,
        'MessageCorrelationId': _newGuid(),
      },
      headers: headers,
    );

    final verifyBody = verifyResponse['body'] as Map<String, dynamic>;
    final statusCode = verifyBody['StatusCode'] as int? ?? -1;
    final errors = _extractErrorMessages(verifyBody);
    if (statusCode != 0) {
      return VerifyPrimaryContactResult(
        isSuccess: false,
        token: '',
        errorCode: errors.isNotEmpty ? errors.first : 'SOMETHING_WENT_WRONG',
      );
    }

    return VerifyPrimaryContactResult(
      isSuccess: true,
      token: token,
      errorCode: null,
    );
  }

  Future<OperationResult> resendVerificationCode({
    required String captchaVerificationCode,
    required String contactVerificationToken,
  }) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/ResendVerificationCode',
      body: <String, dynamic>{
        'CaptchaVerificationCode': captchaVerificationCode,
        'ContactVerificationToken': contactVerificationToken,
        'ContactType': 0,
        'TemplateName': 'UserEmailChangeVerificationByCustomer',
        'MessageCorrelationId': _newGuid(),
      },
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final statusCode = body['StatusCode'] as int? ?? -1;
    final errors = _extractErrorMessages(body);
    return OperationResult(
      isSuccess: statusCode == 0,
      errorCode: statusCode == 0
          ? null
          : (errors.isNotEmpty ? errors.first : 'SOMETHING_WENT_WRONG'),
    );
  }

  Future<OperationResult> confirmEmailChange({
    required String verificationToken,
    required String verificationCode,
    required String oldEmail,
    required String newEmail,
  }) async {
    final headers = await _authorizedHeaders();
    final user = await _requireUser();

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/ChangePrimaryContact',
      body: <String, dynamic>{
        'Token': verificationToken,
        'Code': verificationCode,
        'ContactType': 'Email',
        'OldContact': oldEmail,
        'NewContact': newEmail,
        'PersonId': user.personId,
      },
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    final isValid = errors?['IsValid'] == true;
    final errorMessages = _extractErrorMessages(body);

    return OperationResult(
      isSuccess: isValid,
      errorCode: isValid
          ? null
          : (errorMessages.isNotEmpty
                ? errorMessages.first
                : 'SOMETHING_WENT_WRONG'),
    );
  }

  Future<OperationResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_securityBaseUrl}SecurityCommand/ChangePassword',
      body: <String, dynamic>{
        'OldPassword': oldPassword,
        'NewPassword': newPassword,
      },
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final statusCode = body['StatusCode'] as int? ?? -1;
    if (statusCode == 0) {
      return const OperationResult(isSuccess: true, errorCode: null);
    }

    final errorsMap = body['Errors'];
    String? errorCode;
    if (errorsMap is Map<String, dynamic>) {
      final innerErrors = errorsMap['Errors'];
      if (innerErrors is List && innerErrors.isNotEmpty) {
        final first = innerErrors.first;
        final msg = (first is Map ? first['ErrorMessage'] : null)?.toString() ?? '';
        if (msg.contains('Old password not matched')) {
          errorCode = 'OLD_PASSWORD_NOT_MATCHED';
        } else if (msg.contains('previous passwords')) {
          errorCode = 'PREVIOUS_PASSWORD';
        } else if (msg.isNotEmpty) {
          errorCode = msg;
        }
      }
    }
    return OperationResult(
      isSuccess: false,
      errorCode: errorCode ?? 'SOMETHING_WENT_WRONG',
    );
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

  Future<VerifyPrimaryContactResult> startPhoneVerification({
    required String newPhone,
    required String captchaVerificationCode,
    required String language,
  }) async {
    final headers = await _authorizedHeaders();
    await _requireUser();

    final existsResponse = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/IsUserExistForContact',
      body: <String, dynamic>{
        'ContactType': 'PhoneNumber',
        'Contact': newPhone,
      },
      headers: headers,
    );

    final existsBody = existsResponse['body'] as Map<String, dynamic>;
    if (existsBody['UserExist'] == true) {
      return const VerifyPrimaryContactResult(
        isSuccess: false,
        token: '',
        errorCode: 'USER_EXISTS_WITH_NEW_CONTACT',
      );
    }

    final token = _newGuid();
    final verifyResponse = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/VerifyPrimaryContact',
      body: <String, dynamic>{
        'Token': token,
        'Contact': newPhone,
        'Language': language,
        'ContactType': 1,
        'TemplateName': 'UserDetailPhoneVerifyByCustomer',
        'CaptchaString': captchaVerificationCode,
        'MessageCorrelationId': _newGuid(),
      },
      headers: headers,
    );

    final verifyBody = verifyResponse['body'] as Map<String, dynamic>;
    final statusCode = verifyBody['StatusCode'] as int? ?? -1;
    final errors = _extractErrorMessages(verifyBody);
    if (statusCode != 0) {
      return VerifyPrimaryContactResult(
        isSuccess: false,
        token: '',
        errorCode: errors.isNotEmpty ? errors.first : 'SOMETHING_WENT_WRONG',
      );
    }

    return VerifyPrimaryContactResult(
      isSuccess: true,
      token: token,
      errorCode: null,
    );
  }

  Future<OperationResult> confirmPhoneChange({
    required String verificationToken,
    required String verificationCode,
    required String oldPhone,
    required String newPhone,
  }) async {
    final headers = await _authorizedHeaders();
    final user = await _requireUser();

    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/ChangePrimaryContact',
      body: <String, dynamic>{
        'Token': verificationToken,
        'Code': verificationCode,
        'ContactType': 'PhoneNumber',
        'OldContact': oldPhone,
        'NewContact': newPhone,
        'PersonId': user.personId,
      },
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    final isValid = errors?['IsValid'] == true;
    final errorMessages = _extractErrorMessages(body);

    return OperationResult(
      isSuccess: isValid,
      errorCode: isValid
          ? null
          : (errorMessages.isNotEmpty
                ? errorMessages.first
                : 'SOMETHING_WENT_WRONG'),
    );
  }

  Future<OperationResult> resendPhoneVerificationCode({
    required String captchaVerificationCode,
    required String contactVerificationToken,
  }) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnQuery/ResendVerificationCode',
      body: <String, dynamic>{
        'CaptchaVerificationCode': captchaVerificationCode,
        'ContactVerificationToken': contactVerificationToken,
        'ContactType': 1,
        'TemplateName': 'UserDetailPhoneVerifyByCustomer',
        'MessageCorrelationId': _newGuid(),
      },
      headers: headers,
    );

    final body = response['body'] as Map<String, dynamic>;
    final statusCode = body['StatusCode'] as int? ?? -1;
    final errors = _extractErrorMessages(body);
    return OperationResult(
      isSuccess: statusCode == 0,
      errorCode: statusCode == 0
          ? null
          : (errors.isNotEmpty ? errors.first : 'SOMETHING_WENT_WRONG'),
    );
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final user = await _requireUser();
    return <String, String>{
      'Authorization': 'bearer ${user.accessToken}',
      'Origin': _apiClient.originUrl,
    };
  }

  Future<UserSessionData> _requireUser() async {
    final user = await _sessionCache.resolve();
    if (user == null) {
      throw Exception('UNAUTHORIZED');
    }
    return user;
  }

  List<String> _extractErrorMessages(Map<String, dynamic> body) {
    final fromErrorMessages = body['ErrorMessages'];
    if (fromErrorMessages is List) {
      return fromErrorMessages.map((e) => e.toString()).toList();
    }
    final fromErrors = body['Errors'];
    if (fromErrors is List) {
      return fromErrors.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  String _newGuid() {
    final random = Random.secure();
    const chars = '0123456789abcdef';
    String chunk(int length) =>
        List<String>.generate(length, (_) => chars[random.nextInt(chars.length)])
            .join();
    return '${chunk(8)}-${chunk(4)}-${chunk(4)}-${chunk(4)}-${chunk(12)}';
  }
}
