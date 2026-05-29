import 'dart:math';

import 'package:filip_at_flutter/core/network/api_client.dart';
import 'package:filip_at_flutter/core/storage/app_storage_keys.dart';
import 'package:filip_at_flutter/core/storage/secure_storage_service.dart';
import 'package:filip_at_flutter/features/auth/application/user_session_cache.dart';
import 'package:filip_at_flutter/features/profile/profile_models.dart';

const _kBiometricEnabledKey = 'biometric_fingerprint_enabled';

class ProfileRepository {
  const ProfileRepository({
    required ApiClient apiClient,
    required UserSessionCache userSessionCache,
    required String captchaUrl,
    required SecureStorageService secureStorageService,
  }) : _apiClient = apiClient,
       _sessionCache = userSessionCache,
       _captchaUrl = captchaUrl,
       _storage = secureStorageService;

  final ApiClient _apiClient;
  final UserSessionCache _sessionCache;
  final String _captchaUrl;
  final SecureStorageService _storage;

  Future<bool> getBiometricEnabled() async {
    final val = await _storage.read(_kBiometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _storage.write(key: _kBiometricEnabledKey, value: enabled.toString());
  }

  Future<bool> getDontAskBiometricPrompt() async {
    final val = await _storage.read(AppStorageKeys.biometricDontAskAgain);
    return val == 'true';
  }

  Future<void> setDontAskBiometricPrompt({required bool value}) async {
    await _storage.write(
      key: AppStorageKeys.biometricDontAskAgain,
      value: value.toString(),
    );
  }

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

  Future<bool> getPinStatus() async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.getJson(
      url: '${_securityBaseUrl}SecurityQuery/GetPinStatus',
      headers: headers,
    );
    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return false;
    final body = response['body'];
    if (body == true) return true;
    if (body is Map<String, dynamic>) {
      final inner = body['body'] ?? body['Body'];
      return inner == true;
    }
    return false;
  }

  Future<({bool isSuccess, String? errorCode})> verifyPinForBiometric({
    required String pin,
  }) async {
    final user = await _requireUser();
    final anonymousToken = await _storage.read('anonymous_access_token');
    final response = await _apiClient.postForm(
      url: _apiClient.tokenUrl,
      body: <String, String>{
        'grant_type': 'pin',
        'username': user.email,
        'pin': pin,
      },
      headers: <String, String>{
        'Origin': _apiClient.originUrl,
        if (anonymousToken != null && anonymousToken.isNotEmpty)
          'Authorization': 'bearer $anonymousToken',
      },
    );
    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      return (isSuccess: true, errorCode: null);
    }
    final body = response['body'];
    if (body is Map<String, dynamic>) {
      final errorCode = body['error'] as String? ?? '';
      if (errorCode == 'incorrect_user_name_or_pin' ||
          errorCode == 'Session_Lock_Id') {
        return (isSuccess: false, errorCode: errorCode);
      }
    }
    return (isSuccess: false, errorCode: 'SOMETHING_WENT_WRONG');
  }

  Future<OperationResult> resetPin({
    required String pin,
    required String retypePin,
    required String password,
  }) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_securityBaseUrl}SecurityCommand/resetPin',
      body: <String, dynamic>{
        'Pin': pin,
        'RetypePin': retypePin,
        'Password': password,
      },
      headers: headers,
    );
    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      return const OperationResult(isSuccess: false, errorCode: 'SOMETHING_WENT_WRONG');
    }
    final body = response['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    if (errors?['IsValid'] == true) {
      return const OperationResult(isSuccess: true, errorCode: null);
    }
    final errorMessages = List<dynamic>.from(
      (body['ErrorMessages'] as List<dynamic>?) ?? const <dynamic>[],
    );
    final msg = errorMessages.isNotEmpty ? errorMessages.first.toString() : '';
    if (msg.contains('Wrong password')) {
      return const OperationResult(isSuccess: false, errorCode: 'WRONG_PASSWORD');
    }
    return const OperationResult(isSuccess: false, errorCode: 'SOMETHING_WENT_WRONG');
  }

  Future<OperationResult> setPin({
    required String pin,
    required String retypePin,
  }) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_securityBaseUrl}SecurityCommand/SetPin',
      body: <String, dynamic>{'Pin': pin, 'RetypePin': retypePin},
      headers: headers,
    );
    final body = response['body'];
    if (body is Map<String, dynamic> && body['StatusCode'] == 0) {
      return const OperationResult(isSuccess: true, errorCode: null);
    }
    return const OperationResult(isSuccess: false, errorCode: 'SOMETHING_WENT_WRONG');
  }

  Future<OperationResult> deletePin({required String password}) async {
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_securityBaseUrl}SecurityCommand/DeletePin',
      body: <String, dynamic>{'password': password},
      headers: headers,
    );
    final body = response['body'];
    if (body is Map<String, dynamic> && body['StatusCode'] == 0) {
      return const OperationResult(isSuccess: true, errorCode: null);
    }
    return const OperationResult(isSuccess: false, errorCode: 'WRONG_PASSWORD');
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

  Future<void> storePinCredential({required String pin}) async {
    final user = await _requireUser();
    await _storage.write(key: 'biometric_credential_email', value: user.email);
    await _storage.write(key: 'biometric_credential_pin', value: pin);
  }

  Future<({String email, String pin})?> getPinCredential() async {
    final email = await _storage.read('biometric_credential_email');
    final pin = await _storage.read('biometric_credential_pin');
    if (email == null || email.isEmpty || pin == null || pin.isEmpty) {
      return null;
    }
    return (email: email, pin: pin);
  }

  Future<void> clearPinCredential() async {
    await _storage.write(key: 'biometric_credential_email', value: '');
    await _storage.write(key: 'biometric_credential_pin', value: '');
  }

  Future<void> updateStoredPinIfBiometricEnabled({required String pin}) async {
    final enabled = await getBiometricEnabled();
    if (enabled) {
      await storePinCredential(pin: pin);
    }
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

  Future<GdprConsentState> fetchGdprConsent() async {
    final user = await _requireUser();
    final headers = await _authorizedHeaders();
    final queryNoQuote =
        'Select <ItemId,UserId,UserPnr,IsMarktforschung,IsKundenveranstaltung,IsNewsletter,IsPost,LastUpdateDate,IsAgreedToContinue,IsLatest,IsConsentGivenFromDashBoard,IsElectronicDelivery,IsHousehold>from<GdprUser>where<UserId=__eql(${user.userId}) & IsLatest=__eql(true)>Orderby<LastUpdateDate __desc>pageNumber=<0>pageSize= <1>';
    final queryQuoted =
        "Select <ItemId,UserId,UserPnr,IsMarktforschung,IsKundenveranstaltung,IsNewsletter,IsPost,LastUpdateDate,IsAgreedToContinue,IsLatest,IsConsentGivenFromDashBoard,IsElectronicDelivery,IsHousehold>from<GdprUser>where<UserId=__eql('${user.userId}') & IsLatest=__eql(true)>Orderby<LastUpdateDate __desc>pageNumber=<0>pageSize= <1>";

    final rawItem = await _fetchGdprRow(
      headers: headers,
      queryText: queryNoQuote,
    ) ??
        await _fetchGdprRow(headers: headers, queryText: queryQuoted);
    if (rawItem == null) return const GdprConsentState.empty();

    final item = _extractResultMap(rawItem);
    return GdprConsentState(
      isMarktforschung: _readBool(
        _readValueByKeys(item, const <String>['IsMarktforschung', 'isMarktforschung']),
      ),
      isKundenveranstaltung: _readBool(
        _readValueByKeys(
          item,
          const <String>['IsKundenveranstaltung', 'isKundenveranstaltung'],
        ),
      ),
      isPost: _readBool(_readValueByKeys(item, const <String>['IsPost', 'isPost'])),
      isNewsletter: _readBool(
        _readValueByKeys(item, const <String>['IsNewsletter', 'isNewsletter']),
      ),
      isHousehold: _readBool(
        _readValueByKeys(item, const <String>['IsHousehold', 'isHousehold']),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchGdprRow({
    required Map<String, String> headers,
    required String queryText,
  }) async {
    final response = await _apiClient.postJson(
      url: '${_apiClient.dataCoreUrl}DataManipulationQuery/GetBySQLFilter',
      body: <String, dynamic>{
        'EntityName': 'GdprUser',
        'Text': queryText,
        'ExcludeCount': true,
      },
      headers: headers,
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) return null;

    final body = response['body'] as Map<String, dynamic>;
    final results = body['Results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(results.first as Map);
  }

  Future<OperationResult> updateGdprConsent(GdprConsentState consent) async {
    final user = await _requireUser();
    final headers = await _authorizedHeaders();
    final response = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/SyncGdprConsentStatus',
      body: <String, dynamic>{
        'Pnr': user.customerId,
        'CustomerId': user.userId,
        'IsMarktforschung': consent.isMarktforschung,
        'IsKundenveranstaltung': consent.isKundenveranstaltung,
        'IsPost': consent.isPost,
        'IsNewsletter': consent.isNewsletter,
        'IsHousehold': consent.isHousehold,
        'IsElectronicDelivery': true,
        'LastUpdateDate': DateTime.now().toIso8601String(),
      },
      headers: headers,
    );

    final statusCode = response['statusCode'] as int? ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      return const OperationResult(
        isSuccess: false,
        errorCode: 'SOMETHING_WENT_WRONG',
      );
    }

    final body = response['body'] as Map<String, dynamic>;
    final errors = body['Errors'] as Map<String, dynamic>?;
    final isValid = errors?['IsValid'] == true;
    return OperationResult(
      isSuccess: isValid,
      errorCode: isValid ? null : 'SOMETHING_WENT_WRONG',
    );
  }

  // ─── Delete account ────────────────────────────────────────────────────────

  /// Step 1 — fire-and-forget drop request.
  /// NS: POST {SLSNBusiness}AccountCommand/DropRequest — no response check.
  Future<void> dropRequest() async {
    final user = await _sessionCache.resolve();
    if (user == null) return;
    await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}AccountCommand/DropRequest',
      body: <String, dynamic>{
        'PersonId': user.personId,
        'UserId': user.userId,
      },
      headers: <String, String>{
        'Authorization': 'bearer ${user.accessToken}',
        'Origin': _apiClient.originUrl,
      },
    );
  }

  /// Step 2 — main deletion call (and step 3 with challenge if required).
  /// NS: POST {SLSNBusiness}SlSnCommand/DeletePersonRelatedData
  /// Returns true on success. Handles challenge-response internally.
  Future<bool> deletePersonRelatedData() async {
    final user = await _sessionCache.resolve();
    if (user == null) return false;
    final headers = <String, String>{
      'Authorization': 'bearer ${user.accessToken}',
      'Origin': _apiClient.originUrl,
    };
    final baseBody = <String, dynamic>{
      'Pnr': user.customerId,
      'PersonId': user.personId,
    };

    final res1 = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/DeletePersonRelatedData',
      body: baseBody,
      headers: headers,
    );
    final body1 = res1['body'] as Map<String, dynamic>? ?? {};
    final errors1 = body1['Errors'] as Map<String, dynamic>?;

    if (errors1?['IsValid'] == true) return true;

    // Extract challenge key + code from error list.
    final errorList = errors1?['Errors'] as List<dynamic>? ?? const [];
    String? challengeKey;
    String? challengeCode;
    for (final e in errorList) {
      if (e is! Map) continue;
      final propName = e['PropertyName']?.toString() ?? '';
      final msg = e['ErrorMessage']?.toString() ?? '';
      if (propName == 'ChallangeKey') challengeKey = msg;
      if (propName == 'Code') challengeCode = msg;
    }

    if (challengeKey == null || challengeCode == null) return false;

    // Step 3 — retry with challenge response.
    final res2 = await _apiClient.postJson(
      url: '${_apiClient.slsnBusinessUrl}SlSnCommand/DeletePersonRelatedData',
      body: <String, dynamic>{
        ...baseBody,
        'MessageCorrelationId': challengeKey,
        'Code': challengeCode,
      },
      headers: headers,
    );
    final body2 = res2['body'] as Map<String, dynamic>? ?? {};
    final errors2 = body2['Errors'] as Map<String, dynamic>?;
    return errors2?['IsValid'] == true;
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

  bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  Map<String, dynamic> _extractResultMap(Map<String, dynamic> item) {
    final data = item['Data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return item;
  }

  dynamic _readValueByKeys(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      if (item.containsKey(key)) {
        return item[key];
      }
    }
    return null;
  }
}
