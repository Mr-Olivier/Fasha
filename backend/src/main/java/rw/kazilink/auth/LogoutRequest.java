package rw.kazilink.auth;

/** Optional body for POST /api/auth/logout - `refreshToken` lets us revoke it too, not just the access token (see AuthService.logout). Null/absent is fine (an older client, or one that already dropped its refresh token). */
public record LogoutRequest(String refreshToken) {
}
