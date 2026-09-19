package rw.fasha.user;

/**
 * ACTIVE users can log in normally. SUSPENDED covers README.md section 3's
 * "administrator can suspend inappropriate accounts" - login should reject
 * suspended users even with a correct password (enforced in AuthService).
 */
public enum UserStatus {
    ACTIVE,
    SUSPENDED
}
