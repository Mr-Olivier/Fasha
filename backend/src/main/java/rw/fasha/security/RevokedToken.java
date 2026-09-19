package rw.fasha.security;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * A JWT that's been logged out before its natural expiry.
 *
 * The primary key IS the token's "jti" (JWT ID) claim - not a separate
 * generated id - because all we ever do with this table is "does this jti
 * exist?" (JwtAuthenticationFilter) and "insert this jti" (AuthService.logout).
 */
@Entity
@Table(name = "revoked_tokens")
@Getter
@NoArgsConstructor
public class RevokedToken {

    @Id
    private UUID jti;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    public RevokedToken(UUID jti, Instant expiresAt) {
        this.jti = jti;
        this.expiresAt = expiresAt;
    }
}
