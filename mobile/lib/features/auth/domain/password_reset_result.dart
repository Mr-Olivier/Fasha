/// The result of POST /api/auth/forgot-password.
///
/// [devResetToken] only exists because this project has no real email
/// server yet (see AuthService.forgotPassword on the backend) - a real
/// production version of this class would have just [message], since the
/// actual reset token would only ever be delivered by email, never
/// returned here for anyone to read.
class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message, this.devResetToken});

  final String message;
  final String? devResetToken;

  factory ForgotPasswordResult.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResult(
      message: json['message'] as String,
      devResetToken: json['devResetToken'] as String?,
    );
  }
}
