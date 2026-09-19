package rw.fasha.auth;

import jakarta.validation.constraints.NotBlank;

/** What the Flutter app sends to POST /api/auth/login, as JSON. */
public record LoginRequest(

        @NotBlank(message = "Email is required")
        String email,

        @NotBlank(message = "Password is required")
        String password
) {
}
