package rw.kazilink.admin;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.security.RefreshTokenService;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;
import rw.kazilink.user.UserStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private NotificationService notificationService;

    @Mock
    private AdminAuditService adminAuditService;

    @InjectMocks
    private AdminUserService adminUserService;

    private final UUID adminUserId = UUID.randomUUID();
    private final UUID targetUserId = UUID.randomUUID();

    private User customer() {
        User user = new User("Jane Customer", "jane@example.com", null, "hash", Role.CUSTOMER);
        user.setId(targetUserId);
        return user;
    }

    @Test
    void setStatus_suspendsAnActiveCustomerAndRevokesTheirSessions() {
        User user = customer();
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(user));

        adminUserService.setStatus(adminUserId, targetUserId, UserStatus.SUSPENDED);

        assertThat(user.getStatus()).isEqualTo(UserStatus.SUSPENDED);
        verify(refreshTokenService).revokeAllForUser(targetUserId);
        verify(adminAuditService).record(adminUserId, "USER_SUSPENDED", "USER", targetUserId, user.getEmail());
    }

    @Test
    void setStatus_resumingDoesNotRevokeSessions() {
        User user = customer();
        user.setStatus(UserStatus.SUSPENDED);
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(user));

        adminUserService.setStatus(adminUserId, targetUserId, UserStatus.ACTIVE);

        assertThat(user.getStatus()).isEqualTo(UserStatus.ACTIVE);
        verify(refreshTokenService, never()).revokeAllForUser(any());
    }

    @Test
    void setStatus_refusesToTouchAnAdminAccount() {
        User admin = new User("An Admin", "admin@example.com", null, "hash", Role.ADMIN);
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(admin));

        assertThatThrownBy(() -> adminUserService.setStatus(adminUserId, targetUserId, UserStatus.SUSPENDED))
                .isInstanceOf(CannotModifyAdminException.class);
    }

    @Test
    void setStatus_throwsWhenTheAccountDoesNotExist() {
        when(userRepository.findById(targetUserId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminUserService.setStatus(adminUserId, targetUserId, UserStatus.SUSPENDED))
                .isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void delete_removesACustomerWithNoBookingHistory() {
        User user = customer();
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(user));
        when(bookingRepository.existsByCustomerId(targetUserId)).thenReturn(false);

        adminUserService.delete(adminUserId, targetUserId);

        verify(userRepository).delete(user);
        verify(adminAuditService).record(adminUserId, "USER_DELETED", "USER", targetUserId, user.getEmail());
    }

    @Test
    void delete_refusesACustomerWithBookingHistory() {
        User user = customer();
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(user));
        when(bookingRepository.existsByCustomerId(targetUserId)).thenReturn(true);

        assertThatThrownBy(() -> adminUserService.delete(adminUserId, targetUserId))
                .isInstanceOf(UserHasHistoryException.class);
        verify(userRepository, never()).delete(any());
    }

    @Test
    void delete_removesAProviderWithNoBookingsAlongWithTheirProfileAndServices() {
        User user = new User("A Provider", "provider@example.com", null, "hash", Role.PROVIDER);
        user.setId(targetUserId);
        UUID profileId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(targetUserId, "Alice's Repairs", null, null, null);
        profile.setId(profileId);
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(user));
        when(providerProfileRepository.findByUserId(targetUserId)).thenReturn(Optional.of(profile));
        when(bookingRepository.existsByProviderProfileId(profileId)).thenReturn(false);
        when(serviceListingRepository.findByProviderProfileId(profileId)).thenReturn(List.of());

        adminUserService.delete(adminUserId, targetUserId);

        verify(providerProfileRepository).delete(profile);
        verify(userRepository).delete(user);
    }

    @Test
    void delete_refusesAProviderWithBookingHistory() {
        User user = new User("A Provider", "provider@example.com", null, "hash", Role.PROVIDER);
        user.setId(targetUserId);
        UUID profileId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(targetUserId, "Alice's Repairs", null, null, null);
        profile.setId(profileId);
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(user));
        when(providerProfileRepository.findByUserId(targetUserId)).thenReturn(Optional.of(profile));
        when(bookingRepository.existsByProviderProfileId(profileId)).thenReturn(true);

        assertThatThrownBy(() -> adminUserService.delete(adminUserId, targetUserId))
                .isInstanceOf(UserHasHistoryException.class);
        verify(providerProfileRepository, never()).delete(any());
        verify(userRepository, never()).delete(any());
    }

    @Test
    void delete_refusesToTouchAnAdminAccount() {
        User admin = new User("An Admin", "admin@example.com", null, "hash", Role.ADMIN);
        when(userRepository.findById(targetUserId)).thenReturn(Optional.of(admin));

        assertThatThrownBy(() -> adminUserService.delete(adminUserId, targetUserId))
                .isInstanceOf(CannotModifyAdminException.class);
    }
}
