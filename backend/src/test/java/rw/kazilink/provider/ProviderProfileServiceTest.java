package rw.kazilink.provider;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProviderProfileServiceTest {

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @InjectMocks
    private ProviderProfileService providerProfileService;

    @Test
    void getMyProfile_throwsWhenNoProfileExists() {
        UUID userId = UUID.randomUUID();
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> providerProfileService.getMyProfile(userId))
                .isInstanceOf(ProviderProfileNotFoundException.class);
    }

    @Test
    void getMyProfile_returnsExistingProfile() {
        UUID userId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(userId, "Alice's Repairs", "Phone repair", "Kigali", null);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));

        ProviderProfileResponse response = providerProfileService.getMyProfile(userId);

        assertThat(response.businessName()).isEqualTo("Alice's Repairs");
        assertThat(response.verificationStatus()).isEqualTo(VerificationStatus.PENDING);
    }

    @Test
    void upsertMyProfile_createsANewProfileWhenNoneExists() {
        UUID userId = UUID.randomUUID();
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        var request = new UpsertProviderProfileRequest("Alice's Repairs", "Phone repair", "Kigali", null);
        ProviderProfileResponse response = providerProfileService.upsertMyProfile(userId, request);

        assertThat(response.userId()).isEqualTo(userId);
        assertThat(response.businessName()).isEqualTo("Alice's Repairs");
        assertThat(response.verificationStatus()).isEqualTo(VerificationStatus.PENDING);

        var captor = ArgumentCaptor.forClass(ProviderProfile.class);
        verify(providerProfileRepository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo(userId);
    }

    @Test
    void upsertMyProfile_updatesFieldsOnAnExistingProfileRatherThanCreatingANewOne() {
        UUID userId = UUID.randomUUID();
        ProviderProfile existing = new ProviderProfile(userId, "Old Name", "Old description", "Huye", null);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(existing));

        var request = new UpsertProviderProfileRequest("New Name", "New description", "Kigali", "https://example.com/pic.jpg");
        providerProfileService.upsertMyProfile(userId, request);

        var captor = ArgumentCaptor.forClass(ProviderProfile.class);
        verify(providerProfileRepository).saveAndFlush(captor.capture());
        // Same object identity as `existing`, not a freshly constructed one.
        assertThat(captor.getValue()).isSameAs(existing);
        assertThat(captor.getValue().getBusinessName()).isEqualTo("New Name");
        assertThat(captor.getValue().getLocation()).isEqualTo("Kigali");
    }
}
