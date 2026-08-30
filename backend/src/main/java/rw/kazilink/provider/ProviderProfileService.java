package rw.kazilink.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProviderProfileService {

    private final ProviderProfileRepository providerProfileRepository;

    public ProviderProfileResponse getMyProfile(UUID userId) {
        ProviderProfile profile = providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        return toResponse(profile);
    }

    /**
     * PUT is naturally "create or replace" - so one method handles both a
     * provider's very first profile and every edit after that. We look the
     * profile up by userId first; if it doesn't exist yet, we build a new
     * one, then apply the request's fields either way. This avoids an
     * if/else with the field-copying logic duplicated in both branches.
     */
    @Transactional
    public ProviderProfileResponse upsertMyProfile(UUID userId, UpsertProviderProfileRequest request) {
        ProviderProfile profile = providerProfileRepository.findByUserId(userId)
                .orElseGet(() -> new ProviderProfile(
                        userId, request.businessName(), request.description(), request.location(), request.profileImageUrl()));

        profile.setBusinessName(request.businessName());
        profile.setDescription(request.description());
        profile.setLocation(request.location());
        profile.setProfileImageUrl(request.profileImageUrl());

        providerProfileRepository.save(profile);
        return toResponse(profile);
    }

    private ProviderProfileResponse toResponse(ProviderProfile profile) {
        return new ProviderProfileResponse(
                profile.getId(),
                profile.getUserId(),
                profile.getBusinessName(),
                profile.getDescription(),
                profile.getLocation(),
                profile.getProfileImageUrl(),
                profile.getVerificationStatus(),
                profile.getCreatedAt(),
                profile.getUpdatedAt()
        );
    }
}
