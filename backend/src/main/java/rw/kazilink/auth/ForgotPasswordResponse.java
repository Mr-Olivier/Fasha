package rw.kazilink.auth;

import java.util.UUID;

/**
 * `devResetToken` only exists because this project has no email server to
 * actually deliver a reset link - see AuthService.forgotPassword's Javadoc.
 * A real production API would NEVER put the token in this response; it
 * would only ever leave the server inside an email.
 */
public record ForgotPasswordResponse(String message, UUID devResetToken) {
}
