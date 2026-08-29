package rw.kazilink.auth;

import java.util.UUID;

import rw.kazilink.user.Role;

/**
 * What we send back after a successful register/login. The Flutter app
 * stores `token` in flutter_secure_storage, then attaches it as
 * "Authorization: Bearer <token>" on every future request (via a Dio
 * interceptor, built when we implement this feature's Flutter half).
 */
public record AuthResponse(
        String token,
        UUID userId,
        String name,
        String email,
        Role role
) {
}
