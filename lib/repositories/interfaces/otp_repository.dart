enum OtpPurpose {
  emailConfirmation('email_confirmation'),
  passwordReset('password_reset'),
  login('login');

  const OtpPurpose(this.apiValue);

  final String apiValue;
}

abstract class OtpRepository {
  Future<void> sendOtp({
    required String email,
    required OtpPurpose purpose,
    String? name,
  });

  Future<String> verifyOtp({
    required String email,
    required String otp,
    required OtpPurpose purpose,
  });
}

class OtpException implements Exception {
  const OtpException(this.message);

  final String message;

  @override
  String toString() => message;
}
