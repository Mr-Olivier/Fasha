package rw.fasha.favorite;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * The composite primary key for FavoriteProvider (customer_id,
 * provider_profile_id - see V32__create_favorite_providers.sql). JPA
 * requires equals/hashCode on an @IdClass to match its @Id fields exactly
 * by name, which is why this can't just be a Java record.
 */
public class FavoriteProviderId implements Serializable {

    private UUID customerId;
    private UUID providerProfileId;

    public FavoriteProviderId() {
    }

    public FavoriteProviderId(UUID customerId, UUID providerProfileId) {
        this.customerId = customerId;
        this.providerProfileId = providerProfileId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof FavoriteProviderId that)) return false;
        return Objects.equals(customerId, that.customerId) && Objects.equals(providerProfileId, that.providerProfileId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(customerId, providerProfileId);
    }
}
