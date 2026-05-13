class CaptchaChallenge {
  const CaptchaChallenge({
    required this.id,
    required this.imageBase64,
  });

  final String id;
  final String imageBase64;
}

class VerifyPrimaryContactResult {
  const VerifyPrimaryContactResult({
    required this.isSuccess,
    required this.token,
    required this.errorCode,
  });

  final bool isSuccess;
  final String token;
  final String? errorCode;
}

class OperationResult {
  const OperationResult({
    required this.isSuccess,
    this.errorCode,
  });

  final bool isSuccess;
  final String? errorCode;
}
