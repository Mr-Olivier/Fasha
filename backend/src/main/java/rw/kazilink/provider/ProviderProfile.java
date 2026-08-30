package rw.kazilink.provider;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * Maps to the "provider_profiles" table - one row per provider user.
 *
 * Note there's no @ManyToOne/@OneToOne relationship to the User entity
 * here, just a plain `userId` column. That's deliberate: this feature only
 * ever needs the id itself (to check "is this profile mine?" and to look
 * one up), never User's other fields, so a real JPA relationship would add
 * complexity (lazy-loading, an extra join) for nothing in return.
 */
@Entity
@Table(name = "provider_profiles")
@Getter
@Setter
@NoArgsConstructor
public class ProviderProfile {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "business_name", nullable = false, length = 150)
    private String businessName;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 150)
    private String location;

    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", nullable = false, length = 20)
    private VerificationStatus verificationStatus = VerificationStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public ProviderProfile(UUID userId, String businessName, String description, String location, String profileImageUrl) {
        this.userId = userId;
        this.businessName = businessName;
        this.description = description;
        this.location = location;
        this.profileImageUrl = profileImageUrl;
        this.verificationStatus = VerificationStatus.PENDING;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }
}
