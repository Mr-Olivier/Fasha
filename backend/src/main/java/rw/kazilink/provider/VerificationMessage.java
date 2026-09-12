package rw.kazilink.provider;

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
import rw.kazilink.user.Role;

import java.time.Instant;
import java.util.UUID;

/**
 * One message in the two-way conversation between a provider and admin
 * about their verification (maps to "provider_verification_messages").
 * Immutable once sent, same as the per-booking chat's Message entity -
 * no edit/delete.
 */
@Entity
@Table(name = "provider_verification_messages")
@Getter
@NoArgsConstructor
public class VerificationMessage {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "provider_profile_id", nullable = false)
    private UUID providerProfileId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    /** Always PROVIDER or ADMIN in practice - never CUSTOMER - but reusing the existing Role enum avoids a redundant one just for that. */
    @Enumerated(EnumType.STRING)
    @Column(name = "sender_role", nullable = false, length = 20)
    private Role senderRole;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public VerificationMessage(UUID providerProfileId, UUID senderId, Role senderRole, String body) {
        this.providerProfileId = providerProfileId;
        this.senderId = senderId;
        this.senderRole = senderRole;
        this.body = body;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
