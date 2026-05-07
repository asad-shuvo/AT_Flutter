enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthSessionState {
  const AuthSessionState({
    required this.status,
  });

  factory AuthSessionState.unknown() {
    return const AuthSessionState(status: AuthStatus.unknown);
  }

  factory AuthSessionState.authenticated() {
    return const AuthSessionState(status: AuthStatus.authenticated);
  }

  factory AuthSessionState.unauthenticated() {
    return const AuthSessionState(status: AuthStatus.unauthenticated);
  }

  final AuthStatus status;
}
