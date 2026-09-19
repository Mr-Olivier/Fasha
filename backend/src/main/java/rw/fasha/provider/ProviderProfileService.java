package rw.fasha.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import rw.fasha.favorite.FavoriteProvider;
import rw.fasha.favorite.FavoriteProviderRepository;
import rw.fasha.review.ReviewRepository;
import rw.fasha.service.ServiceListing;
import rw.fasha.service.ServiceListingRepository;
import rw.fasha.service.ServiceListingResponse;
import rw.fasha.user.AvatarStorageService;
import rw.fasha.user.User;
import rw.fasha.user.UserRepository;
import rw.fasha.user.UserStatus;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProviderProfileService {

    private final ProviderProfileRepository providerProfileRepository;
    private final ServiceListingRepository serviceListingRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final AvatarStorageService avatarStorageService;
    private final FavoriteProviderRepository favoriteProviderRepository;

    public ProviderProfileResponse getMyProfile(UUID userId) {
        ProviderProfile profile = providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        return toResponse(profile, Set.of());
    }

    /**
     * Powers customer-facing search (GET /api/providers). Only APPROVED
     * providers are ever returned - an unverified or rejected provider
     * shouldn't be discoverable by customers, even though their profile
     * still exists in the database.
     *
     * categoryId and search combine (AND, not OR) rather than one
     * overriding the other, so narrowing by category first and then typing
     * a search term keeps narrowing instead of resetting the category
     * filter. Filtering happens in memory, same as the categoryId filter
     * already did - fine at this dataset size, and avoids a second query
     * mechanism (JPA Specifications) for what's currently a handful of
     * approved providers.
     *
     * minRating and maxPrice are the Filters sheet's slider/chips - both
     * optional, both AND-combined with everything else. viewerId is the
     * logged-in customer looking at this list (null if anonymous or not a
     * customer), used only to mark which results they've already favorited.
     */
    public List<ProviderProfileResponse> browseProviders(
            UUID categoryId, String search, Double minRating, BigDecimal maxPrice, UUID viewerId
    ) {
        List<ProviderProfile> approved = providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED);
        approved = excludeSuspendedOwners(approved);

        if (categoryId != null) {
            Set<UUID> providerIdsInCategory = serviceListingRepository.findByCategoryIdAndVisibleTrue(categoryId).stream()
                    .map(ServiceListing::getProviderProfileId)
                    .collect(Collectors.toSet());
            approved = approved.stream().filter(p -> providerIdsInCategory.contains(p.getId())).toList();
        }

        String trimmedSearch = search == null ? null : search.trim();
        if (trimmedSearch != null && !trimmedSearch.isEmpty()) {
            String needle = trimmedSearch.toLowerCase();
            approved = approved.stream().filter(p -> matchesSearch(p, needle)).toList();
        }

        if (minRating != null) {
            approved = approved.stream()
                    .filter(p -> reviewRepository.findAverageRatingByProviderProfileId(p.getId()).orElse(0.0) >= minRating)
                    .toList();
        }

        if (maxPrice != null) {
            Map<UUID, BigDecimal> cheapestServiceByProvider = serviceListingRepository.findByVisibleTrue().stream()
                    .collect(Collectors.toMap(
                            ServiceListing::getProviderProfileId,
                            ServiceListing::getPrice,
                            BigDecimal::min));
            approved = approved.stream()
                    .filter(p -> {
                        BigDecimal cheapest = cheapestServiceByProvider.get(p.getId());
                        return cheapest != null && cheapest.compareTo(maxPrice) <= 0;
                    })
                    .toList();
        }

        Set<UUID> favoritedIds = favoritedProviderIds(viewerId);
        return approved.stream().map(p -> toResponse(p, favoritedIds)).toList();
    }

    /** Empty set for an anonymous viewer (or one with no favorites) rather than a null check scattered through toResponse. */
    private Set<UUID> favoritedProviderIds(UUID customerId) {
        if (customerId == null) return Set.of();
        return favoriteProviderRepository.findByCustomerId(customerId).stream()
                .map(FavoriteProvider::getProviderProfileId)
                .collect(Collectors.toSet());
    }

    /**
     * A suspended provider's profile stays APPROVED (suspension is an
     * account-level action, not a re-review of their business - see
     * AdminUserService) but must still disappear from customer-facing
     * search/detail alongside their login being blocked (AuthService.login),
     * or "suspended" wouldn't actually mean anything from a customer's
     * point of view.
     */
    private List<ProviderProfile> excludeSuspendedOwners(List<ProviderProfile> profiles) {
        if (profiles.isEmpty()) return profiles;
        Set<UUID> suspendedOwnerIds = userRepository.findAllById(profiles.stream().map(ProviderProfile::getUserId).distinct().toList())
                .stream()
                .filter(user -> user.getStatus() == UserStatus.SUSPENDED)
                .map(User::getId)
                .collect(Collectors.toSet());
        return profiles.stream().filter(p -> !suspendedOwnerIds.contains(p.getUserId())).toList();
    }

    private boolean isOwnerSuspended(ProviderProfile profile) {
        return userRepository.findById(profile.getUserId())
                .map(user -> user.getStatus() == UserStatus.SUSPENDED)
                .orElse(false);
    }

    /** businessName, location, and description are all customer-visible text a search term could plausibly be typed against. */
    private boolean matchesSearch(ProviderProfile profile, String lowercaseNeedle) {
        return containsIgnoreCase(profile.getBusinessName(), lowercaseNeedle)
                || containsIgnoreCase(profile.getLocation(), lowercaseNeedle)
                || containsIgnoreCase(profile.getDescription(), lowercaseNeedle);
    }

    private boolean containsIgnoreCase(String haystack, String lowercaseNeedle) {
        return haystack != null && haystack.toLowerCase().contains(lowercaseNeedle);
    }

    /**
     * A provider's public detail page (GET /api/providers/{id}) - profile
     * plus every service they offer. Same APPROVED-only rule as
     * browseProviders: a direct link to an unverified provider's id isn't
     * a back door around the search filter.
     */
    public ProviderDetailResponse getProviderDetail(UUID providerProfileId, UUID viewerId) {
        ProviderProfile profile = providerProfileRepository.findById(providerProfileId)
                .filter(p -> p.getVerificationStatus() == VerificationStatus.APPROVED)
                .filter(p -> !isOwnerSuspended(p))
                .orElseThrow(ProviderNotFoundException::new);

        List<ServiceListingResponse> services = serviceListingRepository.findByProviderProfileIdAndVisibleTrue(providerProfileId).stream()
                .map(ServiceListingResponse::from)
                .toList();

        return new ProviderDetailResponse(toResponse(profile, favoritedProviderIds(viewerId)), services);
    }

    /** GET /api/favorites - a customer's own saved providers, most recently favorited not tracked (order matches findByCustomerId's natural order). */
    public List<ProviderProfileResponse> listFavoriteProviders(UUID customerId) {
        Set<UUID> favoritedIds = favoritedProviderIds(customerId);
        return providerProfileRepository.findAllById(favoritedIds).stream()
                .map(p -> toResponse(p, favoritedIds))
                .toList();
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
        profile.setCategoryId(request.categoryId());
        profile.setYearsExperience(request.yearsExperience());

        // saveAndFlush, not save: the @PreUpdate callback on ProviderProfile
        // that bumps updatedAt only actually runs when Hibernate flushes to
        // the database - plain save() just queues the write for later
        // (normally at transaction commit). Without the explicit flush here,
        // toResponse() below would read updatedAt's STALE in-memory value
        // (this bit us during manual testing: the response showed the old
        // timestamp even though the correct new one was already in Postgres).
        providerProfileRepository.saveAndFlush(profile);
        return toResponse(profile, Set.of());
    }

    /**
     * A provider's public business photo - same trust level as a user
     * avatar (shown on their public profile, anyone can view), so this
     * deliberately reuses AvatarStorageService rather than the private
     * SecureFileStorageService KYC documents use.
     */
    @Transactional
    public ProviderProfileResponse updatePhoto(UUID userId, MultipartFile file) {
        ProviderProfile profile = providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        profile.setProfileImageUrl(avatarStorageService.store(userId, file));
        providerProfileRepository.saveAndFlush(profile);
        return toResponse(profile, Set.of());
    }

    private ProviderProfileResponse toResponse(ProviderProfile profile, Set<UUID> favoritedProviderIds) {
        Double averageRating = reviewRepository.findAverageRatingByProviderProfileId(profile.getId()).orElse(null);
        long reviewCount = reviewRepository.countByProviderProfileId(profile.getId());

        return new ProviderProfileResponse(
                profile.getId(),
                profile.getUserId(),
                profile.getBusinessName(),
                profile.getDescription(),
                profile.getLocation(),
                profile.getProfileImageUrl(),
                profile.getCategoryId(),
                profile.getYearsExperience(),
                profile.getVerificationStatus(),
                averageRating,
                reviewCount,
                profile.getId() != null && favoritedProviderIds.contains(profile.getId()),
                profile.getCreatedAt(),
                profile.getUpdatedAt()
        );
    }
}
