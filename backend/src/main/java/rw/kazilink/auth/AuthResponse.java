package rw.kazilink.auth;

import java.util.UUID;

import rw.kazilink.user.Role;

/**
 * What we send back after a successful register/login/refresh. The
 * Flutter app stores both tokens in flutter_secure_storage: `token` (a
 * short-lived access token) gets attached as "Authorization: Bearer
 * <token>" on every request, while `refreshToken` is only ever sent to
 * POST /api/auth/refresh, to get a new pair once the access token expires
 * - see RefreshTokenService's Javadoc for why they're split like this.
 *
 * `phone`/`profileImageUrl` are included here (not just GET /api/users/me)
 * so a freshly logged-in session already has them without a second
 * round-trip - a user's avatar used to only appear after they opened the
 * Profile tab once per session.
 */
public record AuthResponse(
        String token,
        String refreshToken,
        UUID userId,
        String name,
        String email,
        String phone,
        String profileImageUrl,
        Role role,
        boolean emailVerified
) {
}
