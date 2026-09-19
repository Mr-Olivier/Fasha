package rw.fasha.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.fasha.category.CategoryRepository;
import rw.fasha.provider.ProviderProfile;
import rw.fasha.provider.ProviderProfileNotFoundException;
import rw.fasha.provider.ProviderProfileRepository;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ServiceListingServiceTest {

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @InjectMocks
    private ServiceListingService serviceListingService;

    private UUID userId;
    private UUID providerProfileId;
    private UUID categoryId;

    @Test
    void addService_requiresAnExistingProviderProfile() {
        userId = UUID.randomUUID();
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        var request = new UpsertServiceListingRequest(UUID.randomUUID(), "Fix taps", null, BigDecimal.TEN, ServiceDuration.ONE_TO_TWO_HOURS, true);

        assertThatThrownBy(() -> serviceListingService.addService(userId, request))
                .isInstanceOf(ProviderProfileNotFoundException.class);
    }

    @Test
    void addService_rejectsAnUnknownCategory() {
        setUpExistingProfile();
        categoryId = UUID.randomUUID();
        when(categoryRepository.existsById(categoryId)).thenReturn(false);

        var request = new UpsertServiceListingRequest(categoryId, "Fix taps", null, BigDecimal.TEN, ServiceDuration.ONE_TO_TWO_HOURS, true);

        assertThatThrownBy(() -> serviceListingService.addService(userId, request))
                .isInstanceOf(InvalidCategoryException.class);
    }

    @Test
    void addService_savesAListingUnderTheCallersProviderProfile() {
        setUpExistingProfile();
        categoryId = UUID.randomUUID();
        when(categoryRepository.existsById(categoryId)).thenReturn(true);

        var request = new UpsertServiceListingRequest(categoryId, "Fix taps", "Leaky tap repair", new BigDecimal("15.00"), ServiceDuration.ONE_TO_TWO_HOURS, true);
        ServiceListingResponse response = serviceListingService.addService(userId, request);

        assertThat(response.providerProfileId()).isEqualTo(providerProfileId);
        assertThat(response.name()).isEqualTo("Fix taps");

        var captor = ArgumentCaptor.forClass(ServiceListing.class);
        verify(serviceListingRepository).save(captor.capture());
        assertThat(captor.getValue().getProviderProfileId()).isEqualTo(providerProfileId);
    }

    @Test
    void updateService_rejectsAServiceBelongingToAnotherProvider() {
        setUpExistingProfile();
        categoryId = UUID.randomUUID();

        // No categoryRepository stub here: ownership is checked BEFORE the
        // category is validated (see ServiceListingService.updateService),
        // so this never even reaches that check - stubbing it would be
        // dead code Mockito's strict stubbing correctly flags as unused.
        UUID serviceId = UUID.randomUUID();
        ServiceListing someoneElsesListing =
                new ServiceListing(UUID.randomUUID(), categoryId, "Existing", null, BigDecimal.ONE);
        when(serviceListingRepository.findById(serviceId)).thenReturn(Optional.of(someoneElsesListing));

        var request = new UpsertServiceListingRequest(categoryId, "New name", null, BigDecimal.TEN, ServiceDuration.ONE_TO_TWO_HOURS, true);

        assertThatThrownBy(() -> serviceListingService.updateService(userId, serviceId, request))
                .isInstanceOf(ServiceListingNotFoundException.class);
    }

    @Test
    void updateService_updatesFieldsWhenTheServiceBelongsToTheCaller() {
        setUpExistingProfile();
        categoryId = UUID.randomUUID();
        when(categoryRepository.existsById(categoryId)).thenReturn(true);

        UUID serviceId = UUID.randomUUID();
        ServiceListing ownListing = new ServiceListing(providerProfileId, categoryId, "Old name", null, BigDecimal.ONE);
        when(serviceListingRepository.findById(serviceId)).thenReturn(Optional.of(ownListing));

        var request = new UpsertServiceListingRequest(categoryId, "New name", "New description", new BigDecimal("20.00"), ServiceDuration.HALF_DAY, false);
        ServiceListingResponse response = serviceListingService.updateService(userId, serviceId, request);

        assertThat(response.name()).isEqualTo("New name");
        assertThat(response.price()).isEqualByComparingTo("20.00");
        assertThat(response.duration()).isEqualTo(ServiceDuration.HALF_DAY);
        assertThat(response.visible()).isFalse();
        verify(serviceListingRepository).save(any(ServiceListing.class));
    }

    @Test
    void setVisibility_togglesOnlyTheVisibleFlag() {
        setUpExistingProfile();
        UUID serviceId = UUID.randomUUID();
        ServiceListing ownListing = new ServiceListing(providerProfileId, UUID.randomUUID(), "Old name", null, BigDecimal.ONE);
        when(serviceListingRepository.findById(serviceId)).thenReturn(Optional.of(ownListing));

        ServiceListingResponse response = serviceListingService.setVisibility(userId, serviceId, false);

        assertThat(response.visible()).isFalse();
        assertThat(response.name()).isEqualTo("Old name");
        verify(serviceListingRepository).save(any(ServiceListing.class));
    }

    private void setUpExistingProfile() {
        userId = UUID.randomUUID();
        providerProfileId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(userId, "Test Business", null, null, null);
        profile.setId(providerProfileId);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));
    }
}
