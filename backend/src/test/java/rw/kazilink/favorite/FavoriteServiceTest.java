package rw.kazilink.favorite;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.provider.ProviderNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FavoriteServiceTest {

    @Mock
    private FavoriteProviderRepository favoriteProviderRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @InjectMocks
    private FavoriteService favoriteService;

    private final UUID customerId = UUID.randomUUID();
    private final UUID providerProfileId = UUID.randomUUID();

    @Test
    void add_rejectsAnUnknownProvider() {
        when(providerProfileRepository.existsById(providerProfileId)).thenReturn(false);

        assertThatThrownBy(() -> favoriteService.add(customerId, providerProfileId))
                .isInstanceOf(ProviderNotFoundException.class);
        verify(favoriteProviderRepository, never()).save(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void add_savesANewFavorite() {
        when(providerProfileRepository.existsById(providerProfileId)).thenReturn(true);
        when(favoriteProviderRepository.existsByCustomerIdAndProviderProfileId(customerId, providerProfileId)).thenReturn(false);

        favoriteService.add(customerId, providerProfileId);

        verify(favoriteProviderRepository).save(org.mockito.ArgumentMatchers.any(FavoriteProvider.class));
    }

    @Test
    void add_isANoOpWhenAlreadyFavorited() {
        when(providerProfileRepository.existsById(providerProfileId)).thenReturn(true);
        when(favoriteProviderRepository.existsByCustomerIdAndProviderProfileId(customerId, providerProfileId)).thenReturn(true);

        favoriteService.add(customerId, providerProfileId);

        verify(favoriteProviderRepository, never()).save(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void remove_delegatesToTheRepositoryEvenIfNeverFavorited() {
        favoriteService.remove(customerId, providerProfileId);

        verify(favoriteProviderRepository).deleteByCustomerIdAndProviderProfileId(customerId, providerProfileId);
    }
}
