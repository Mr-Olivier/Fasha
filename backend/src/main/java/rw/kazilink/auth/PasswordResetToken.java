package rw.kazilink.auth;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/** One row per "forgot password" request - see V7's migration comment for why the token itself is the primary key. */
@Entity
@Table(name = "password_reset_tokens")
@Getter
@Setter
@NoArgsConstructor
public class PasswordResetToken {

    /**
     * Generated here in Java (not via {@code @GeneratedValue}) because
     * AuthService needs the token's value immediately - to log/return it -
     * in the same call that creates it, before any database round-trip
     * would otherwise assign one.
     */
    @Id
    private UUID token;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public PasswordResetToken(UUID userId, Instant expiresAt) {
        this.token = UUID.randomUUID();
        this.userId = userId;
        this.expiresAt = expiresAt;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public boolean isValid() {
        return usedAt == null && expiresAt.isAfter(Instant.now());
    }
}
