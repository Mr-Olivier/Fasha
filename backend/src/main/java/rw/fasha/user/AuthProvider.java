package rw.fasha.user;

/**
 * How a user proves who they are. LOCAL means email+password (the original
 * flow); GOOGLE means they signed in with a Google account and have no
 * password_hash at all - see AuthService.googleAuth() and the CHECK
 * constraint added in V16__add_google_auth_to_users.sql.
 */
public enum AuthProvider {
    LOCAL,
    GOOGLE
}
