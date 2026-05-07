class AuthException implements Exception {
  const AuthException({
    required this.message,
    this.code,
    this.description,
  });

  final String message;
  final String? code;
  final String? description;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
