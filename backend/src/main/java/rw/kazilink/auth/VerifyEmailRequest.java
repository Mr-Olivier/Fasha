package rw.kazilink.auth;

import jakarta.validation.constraints.NotBlank;

/** Body for POST /api/auth/verify-email - the caller is already authenticated (their own just-issued JWT from register()), so only the code itself is needed. */
public record VerifyEmailRequest(
        @NotBlank(message = "Code is required")
        String code
) {
}
