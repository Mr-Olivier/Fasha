package rw.kazilink.admin;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.provider.VerificationStatus;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminProviderServiceTest {

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @Mock
    private NotificationService notificationService;

    @Mock
    private AdminAuditService adminAuditService;

    @InjectMocks
    private AdminProviderService adminProviderService;

    private final UUID userId = UUID.randomUUID();
    private final UUID profileId = UUID.randomUUID();
    private final UUID adminUserId = UUID.randomUUID();

    private ProviderProfile pendingProfile() {
        ProviderProfile profile = new ProviderProfile(userId, "Kigali Cool Fridges", "Fridge repair", "Gasabo", null);
        profile.setId(profileId);
        return profile;
    }

    @Test
    void listProviders_filtersByTheGivenStatus() {
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.PENDING))
                .thenReturn(List.of(pendingProfile()));
        when(userRepository.findById(userId))
                .thenReturn(Optional.of(new User("Patrick N.", "patrick@example.com", "0788456123", "hash", Role.PROVIDER)));
        when(serviceListingRepository.countByProviderProfileId(profileId)).thenReturn(3L);

        List<PendingProviderResponse> results = adminProviderService.listProviders(VerificationStatus.PENDING);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Kigali Cool Fridges");
        assertThat(results.get(0).ownerName()).isEqualTo("Patrick N.");
        assertThat(results.get(0).serviceCount()).isEqualTo(3L);
    }

    @Test
    void decide_approvedTrue_movesProfileToApproved() {
        ProviderProfile profile = pendingProfile();
        when(providerProfileRepository.findById(profileId)).thenReturn(Optional.of(profile));
        when(userRepository.findById(userId))
                .thenReturn(Optional.of(new User("Patrick N.", "patrick@example.com", "0788456123", "hash", Role.PROVIDER)));
        when(serviceListingRepository.countByProviderProfileId(profileId)).thenReturn(0L);

        PendingProviderResponse response = adminProviderService.decide(adminUserId, profileId, true);

        assertThat(response.verificationStatus()).isEqualTo(VerificationStatus.APPROVED);
        assertThat(profile.getVerificationStatus()).isEqualTo(VerificationStatus.APPROVED);
    }

    @Test
    void decide_approvedFalse_movesProfileToRejected() {
        ProviderProfile profile = pendingProfile();
        when(providerProfileRepository.findById(profileId)).thenReturn(Optional.of(profile));
        when(userRepository.findById(userId))
                .thenReturn(Optional.of(new User("Patrick N.", "patrick@example.com", "0788456123", "hash", Role.PROVIDER)));
        when(serviceListingRepository.countByProviderProfileId(profileId)).thenReturn(0L);

        PendingProviderResponse response = adminProviderService.decide(adminUserId, profileId, false);

        assertThat(response.verificationStatus()).isEqualTo(VerificationStatus.REJECTED);
    }

    @Test
    void decide_throwsWhenTheProviderProfileDoesNotExist() {
        when(providerProfileRepository.findById(profileId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminProviderService.decide(adminUserId, profileId, true))
                .isInstanceOf(ProviderProfileNotFoundException.class);
    }
}
