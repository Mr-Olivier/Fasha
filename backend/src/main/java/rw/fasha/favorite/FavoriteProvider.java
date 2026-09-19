package rw.fasha.favorite;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * A customer's saved provider (the profile screen's favorite heart) - see
 * V32__create_favorite_providers.sql. No surrogate id: the (customer,
 * provider) pair IS the identity, hence @IdClass instead of the usual
 * single @GeneratedValue id every other entity here uses.
 */
@Entity
@Table(name = "favorite_providers")
@IdClass(FavoriteProviderId.class)
@Getter
@NoArgsConstructor
public class FavoriteProvider {

    @Id
    @Column(name = "customer_id")
    private UUID customerId;

    @Id
    @Column(name = "provider_profile_id")
    private UUID providerProfileId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public FavoriteProvider(UUID customerId, UUID providerProfileId) {
        this.customerId = customerId;
        this.providerProfileId = providerProfileId;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
