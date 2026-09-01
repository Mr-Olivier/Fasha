/// The result of POST /api/auth/forgot-password. Just a message now - the
/// actual OTP code only ever leaves the backend inside an email sent via
/// Brevo (see AuthService.forgotPassword's Javadoc on the backend).
class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message});

  final String message;

  factory ForgotPasswordResult.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResult(message: json['message'] as String);
  }
}
