package rw.fasha.favorite;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.fasha.provider.ProviderNotFoundException;
import rw.fasha.provider.ProviderProfileRepository;

import java.util.UUID;

/**
 * The favorite/save-provider heart icon on a provider's profile. Both
 * operations are idempotent (favoriting twice, or unfavoriting something
 * never favorited, are both no-ops) since the UI just toggles a boolean
 * and shouldn't have to track whether it's already in the state it wants.
 */
@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteProviderRepository favoriteProviderRepository;
    private final ProviderProfileRepository providerProfileRepository;

    @Transactional
    public void add(UUID customerId, UUID providerProfileId) {
        if (!providerProfileRepository.existsById(providerProfileId)) {
            throw new ProviderNotFoundException();
        }
        if (!favoriteProviderRepository.existsByCustomerIdAndProviderProfileId(customerId, providerProfileId)) {
            favoriteProviderRepository.save(new FavoriteProvider(customerId, providerProfileId));
        }
    }

    @Transactional
    public void remove(UUID customerId, UUID providerProfileId) {
        favoriteProviderRepository.deleteByCustomerIdAndProviderProfileId(customerId, providerProfileId);
    }
}
