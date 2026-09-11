package rw.kazilink.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
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
import java.util.UUID;

/**
 * Admin's power over customer and provider accounts: list them, suspend/
 * resume (blocks/restores login - see AuthService.login - and, for a
 * provider, drops them out of public search too - see
 * ProviderProfileService.excludeSuspendedOwners), or permanently delete
 * one. Deliberately excludes ADMIN accounts as a target - see
 * CannotModifyAdminException.
 *
 * Delete is GUARDED, not unconditional: an account with real booking
 * history (as a customer, or as a provider who's taken bookings) can only
 * be suspended, never deleted - removing it would either orphan that
 * booking history's customer/provider reference or silently destroy
 * records of real transactions, neither of which is acceptable. A
 * never-booked account has no such history to protect, so it can go.
 */
@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserRepository userRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final ServiceListingRepository serviceListingRepository;
    private final BookingRepository bookingRepository;
    private final RefreshTokenService refreshTokenService;
    private final NotificationService notificationService;
    private final AdminAuditService adminAuditService;

    public List<AdminUserResponse> list(Role role) {
        List<User> users = role != null ? userRepository.findByRoleOrderByCreatedAtDesc(role) : userRepository.findAll();
        return users.stream().map(this::toResponse).toList();
    }

    @Transactional
    public AdminUserResponse setStatus(UUID adminUserId, UUID targetUserId, UserStatus newStatus) {
        User target = userRepository.findById(targetUserId).orElseThrow(UserNotFoundException::new);
        if (target.getRole() == Role.ADMIN) {
            throw new CannotModifyAdminException();
        }

        target.setStatus(newStatus);
        userRepository.save(target);

        // A suspended account's EXISTING sessions must die immediately, not
        // just be blocked from logging in again - otherwise a still-valid
        // access token (up to 15 minutes) or refresh token (up to 30 days)
        // would keep working right through the suspension.
        if (newStatus == UserStatus.SUSPENDED) {
            refreshTokenService.revokeAllForUser(targetUserId);
        }

        notificationService.create(
                targetUserId,
                newStatus == UserStatus.SUSPENDED ? "Account suspended" : "Account reactivated",
                newStatus == UserStatus.SUSPENDED
                        ? "Your account has been suspended by an administrator. Contact support if you believe this is a mistake."
                        : "Your account has been reactivated - welcome back!",
                null);
        adminAuditService.record(
                adminUserId, newStatus == UserStatus.SUSPENDED ? "USER_SUSPENDED" : "USER_RESUMED", "USER", targetUserId, target.getEmail());

        return toResponse(target);
    }

    @Transactional
    public void delete(UUID adminUserId, UUID targetUserId) {
        User target = userRepository.findById(targetUserId).orElseThrow(UserNotFoundException::new);
        if (target.getRole() == Role.ADMIN) {
            throw new CannotModifyAdminException();
        }

        if (target.getRole() == Role.PROVIDER) {
            ProviderProfile profile = providerProfileRepository.findByUserId(targetUserId).orElse(null);
            if (profile != null) {
                if (bookingRepository.existsByProviderProfileId(profile.getId())) {
                    throw new UserHasHistoryException();
                }
                serviceListingRepository.deleteAll(serviceListingRepository.findByProviderProfileId(profile.getId()));
                providerProfileRepository.delete(profile);
            }
        } else if (target.getRole() == Role.CUSTOMER && bookingRepository.existsByCustomerId(targetUserId)) {
            throw new UserHasHistoryException();
        }

        refreshTokenService.revokeAllForUser(targetUserId);
        userRepository.delete(target);
        adminAuditService.record(adminUserId, "USER_DELETED", "USER", targetUserId, target.getEmail());
    }

    private AdminUserResponse toResponse(User user) {
        return new AdminUserResponse(
                user.getId(), user.getName(), user.getEmail(), user.getPhone(),
                user.getRole(), user.getStatus(), user.getProfileImageUrl(), user.getCreatedAt()
        );
    }
}
