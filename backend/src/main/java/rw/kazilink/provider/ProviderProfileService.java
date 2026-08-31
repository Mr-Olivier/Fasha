package rw.kazilink.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.review.ReviewRepository;
import rw.kazilink.service.ServiceListing;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.service.ServiceListingResponse;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProviderProfileService {

    private final ProviderProfileRepository providerProfileRepository;
    private final ServiceListingRepository serviceListingRepository;
    private final ReviewRepository reviewRepository;

    public ProviderProfileResponse getMyProfile(UUID userId) {
        ProviderProfile profile = providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        return toResponse(profile);
    }

    /**
     * Powers customer-facing search (GET /api/providers). Only APPROVED
     * providers are ever returned - an unverified or rejected provider
     * shouldn't be discoverable by customers, even though their profile
     * still exists in the database.
     */
    public List<ProviderProfileResponse> browseProviders(UUID categoryId) {
        List<ProviderProfile> approved = providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED);

        if (categoryId != null) {
            Set<UUID> providerIdsInCategory = serviceListingRepository.findByCategoryId(categoryId).stream()
                    .map(ServiceListing::getProviderProfileId)
                    .collect(Collectors.toSet());
            approved = approved.stream().filter(p -> providerIdsInCategory.contains(p.getId())).toList();
        }

        return approved.stream().map(this::toResponse).toList();
    }

    /**
     * A provider's public detail page (GET /api/providers/{id}) - profile
     * plus every service they offer. Same APPROVED-only rule as
     * browseProviders: a direct link to an unverified provider's id isn't
     * a back door around the search filter.
     */
    public ProviderDetailResponse getProviderDetail(UUID providerProfileId) {
        ProviderProfile profile = providerProfileRepository.findById(providerProfileId)
                .filter(p -> p.getVerificationStatus() == VerificationStatus.APPROVED)
                .orElseThrow(ProviderNotFoundException::new);

        List<ServiceListingResponse> services = serviceListingRepository.findByProviderProfileId(providerProfileId).stream()
                .map(ServiceListingResponse::from)
                .toList();

        return new ProviderDetailResponse(toResponse(profile), services);
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

        // saveAndFlush, not save: the @PreUpdate callback on ProviderProfile
        // that bumps updatedAt only actually runs when Hibernate flushes to
        // the database - plain save() just queues the write for later
        // (normally at transaction commit). Without the explicit flush here,
        // toResponse() below would read updatedAt's STALE in-memory value
        // (this bit us during manual testing: the response showed the old
        // timestamp even though the correct new one was already in Postgres).
        providerProfileRepository.saveAndFlush(profile);
        return toResponse(profile);
    }

    private ProviderProfileResponse toResponse(ProviderProfile profile) {
        Double averageRating = reviewRepository.findAverageRatingByProviderProfileId(profile.getId()).orElse(null);
        long reviewCount = reviewRepository.countByProviderProfileId(profile.getId());

        return new ProviderProfileResponse(
                profile.getId(),
                profile.getUserId(),
                profile.getBusinessName(),
                profile.getDescription(),
                profile.getLocation(),
                profile.getProfileImageUrl(),
                profile.getVerificationStatus(),
                averageRating,
                reviewCount,
                profile.getCreatedAt(),
                profile.getUpdatedAt()
        );
    }
}
