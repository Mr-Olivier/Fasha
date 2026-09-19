package rw.fasha.auth;

import jakarta.validation.constraints.NotBlank;
import rw.fasha.user.Role;

/**
 * What the Flutter app sends to POST /api/auth/google after Google's own
 * sign-in picker hands it an ID token.
 *
 * [role] is only read the first time this Google account is seen (a
 * brand-new user) - see AuthService.googleAuth(). It's ignored for an
 * existing account, whose role is already set, so the field is optional
 * here rather than @NotNull like RegisterRequest's.
 */
public record GoogleAuthRequest(

        @NotBlank(message = "Google ID token is required")
        String idToken,

        Role role
) {
}
