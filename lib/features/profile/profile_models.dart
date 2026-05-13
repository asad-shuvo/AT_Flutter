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

class GdprConsentState {
  const GdprConsentState({
    required this.isMarktforschung,
    required this.isKundenveranstaltung,
    required this.isPost,
    required this.isNewsletter,
    required this.isHousehold,
  });

  const GdprConsentState.empty()
    : isMarktforschung = false,
      isKundenveranstaltung = false,
      isPost = false,
      isNewsletter = false,
      isHousehold = false;

  final bool isMarktforschung;
  final bool isKundenveranstaltung;
  final bool isPost;
  final bool isNewsletter;
  final bool isHousehold;

  GdprConsentState copyWith({
    bool? isMarktforschung,
    bool? isKundenveranstaltung,
    bool? isPost,
    bool? isNewsletter,
    bool? isHousehold,
  }) {
    return GdprConsentState(
      isMarktforschung: isMarktforschung ?? this.isMarktforschung,
      isKundenveranstaltung:
          isKundenveranstaltung ?? this.isKundenveranstaltung,
      isPost: isPost ?? this.isPost,
      isNewsletter: isNewsletter ?? this.isNewsletter,
      isHousehold: isHousehold ?? this.isHousehold,
    );
  }
}
