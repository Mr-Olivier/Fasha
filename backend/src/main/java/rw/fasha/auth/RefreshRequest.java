package rw.fasha.auth;

import jakarta.validation.constraints.NotBlank;

/** Body for POST /api/auth/refresh. */
public record RefreshRequest(
        @NotBlank(message = "refreshToken is required")
        String refreshToken
) {
}
