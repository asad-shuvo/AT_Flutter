class RememberMeInfo {
  const RememberMeInfo({
    required this.isEnabled,
    required this.email,
    required this.password,
  });

  const RememberMeInfo.empty()
      : isEnabled = false,
        email = '',
        password = '';

  final bool isEnabled;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isRememberMeEnabled': isEnabled,
      'email': email,
      'password': password,
    };
  }

  factory RememberMeInfo.fromJson(Map<String, dynamic> json) {
    return RememberMeInfo(
      isEnabled: json['isRememberMeEnabled'] == true,
      email: (json['email'] as String?) ?? '',
      password: (json['password'] as String?) ?? '',
    );
  }
}
