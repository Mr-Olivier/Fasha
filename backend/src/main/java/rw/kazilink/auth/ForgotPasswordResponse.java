package rw.kazilink.auth;

/** What POST /api/auth/forgot-password always returns - the actual code only ever leaves the server inside an email now (see AuthService.forgotPassword's Javadoc for why the message is identical whether or not the email exists). */
public record ForgotPasswordResponse(String message) {
}
