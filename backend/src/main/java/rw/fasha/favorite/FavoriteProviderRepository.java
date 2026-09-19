package rw.fasha.favorite;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FavoriteProviderRepository extends JpaRepository<FavoriteProvider, FavoriteProviderId> {

    boolean existsByCustomerIdAndProviderProfileId(UUID customerId, UUID providerProfileId);

    void deleteByCustomerIdAndProviderProfileId(UUID customerId, UUID providerProfileId);

    /** Powers both "my favorites" list and the isFavorited flag on every provider in a browse result (see ProviderProfileService). */
    List<FavoriteProvider> findByCustomerId(UUID customerId);
}
