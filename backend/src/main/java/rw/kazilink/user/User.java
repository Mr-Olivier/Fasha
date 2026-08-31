package rw.kazilink.user;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * Maps 1:1 to the "users" table (see db/migration/V1__create_users_table.sql).
 *
 * We deliberately use only @Getter/@Setter from Lombok here, never @Data.
 * @Data also generates equals()/hashCode()/toString(), which is dangerous on
 * JPA entities - it can trigger extra database queries just to print a log
 * line, or break badly once entities have relationships to each other.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, unique = true, length = 190)
    private String email;

    @Column(length = 30)
    private String phone;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserStatus status = UserStatus.ACTIVE;

    /** Set by UserService's avatar upload endpoint; null until the user uploads one. */
    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    /** Constructor used by AuthService when registering a new user. */
    public User(String name, String email, String phone, String passwordHash, Role role) {
        this.name = name;
        this.email = email;
        this.phone = phone;
        this.passwordHash = passwordHash;
        this.role = role;
        this.status = UserStatus.ACTIVE;
    }

    // Hibernate calls this automatically right before the first INSERT, so
    // callers never need to remember to set createdAt themselves.
    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
