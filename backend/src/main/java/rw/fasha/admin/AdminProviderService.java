package rw.fasha.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.fasha.notification.NotificationService;
import rw.fasha.provider.ProviderProfile;
import rw.fasha.provider.ProviderProfileNotFoundException;
import rw.fasha.provider.ProviderProfileRepository;
import rw.fasha.provider.VerificationStatus;
import rw.fasha.service.ServiceListingRepository;
import rw.fasha.user.User;
import rw.fasha.user.UserNotFoundException;
import rw.fasha.user.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminProviderService {

    private final ProviderProfileRepository providerProfileRepository;
    private final UserRepository userRepository;
    private final ServiceListingRepository serviceListingRepository;
    private final NotificationService notificationService;
    private final AdminAuditService adminAuditService;

    /**
     * status is optional - omitting it (plain GET /api/admin/providers) lists
     * every provider regardless of status, which is what a future "all
     * providers" admin screen needs; passing status=PENDING is what the
     * approval queue actually uses today.
     */
    public List<PendingProviderResponse> listProviders(VerificationStatus status) {
        List<ProviderProfile> profiles = status != null
                ? providerProfileRepository.findByVerificationStatus(status)
                : providerProfileRepository.findAll();
        return profiles.stream().map(this::toResponse).toList();
    }

    @Transactional
    public PendingProviderResponse decide(UUID adminUserId, UUID providerProfileId, boolean approved) {
        ProviderProfile profile = providerProfileRepository.findById(providerProfileId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        profile.setVerificationStatus(approved ? VerificationStatus.APPROVED : VerificationStatus.REJECTED);
        providerProfileRepository.save(profile);

        notificationService.create(
                profile.getUserId(),
                approved ? "Application approved" : "Application rejected",
                approved
                        ? "Your provider application for " + profile.getBusinessName() + " was approved - you're now visible in search."
                        : "Your provider application for " + profile.getBusinessName() + " wasn't approved this time.",
                null);
        adminAuditService.record(adminUserId, approved ? "PROVIDER_APPROVED" : "PROVIDER_REJECTED", "PROVIDER_PROFILE",
                profile.getId(), profile.getBusinessName());

        return toResponse(profile);
    }

    private PendingProviderResponse toResponse(ProviderProfile profile) {
        User owner = userRepository.findById(profile.getUserId()).orElseThrow(UserNotFoundException::new);
        long serviceCount = serviceListingRepository.countByProviderProfileId(profile.getId());

        return new PendingProviderResponse(
                profile.getId(),
                profile.getBusinessName(),
                profile.getDescription(),
                profile.getLocation(),
                profile.getVerificationStatus(),
                profile.getCreatedAt(),
                owner.getId(),
                owner.getName(),
                owner.getEmail(),
                owner.getPhone(),
                owner.getStatus(),
                serviceCount,
                profile.getDocumentsSubmittedAt() != null
        );
    }
}
