package rw.fasha.provider;

import java.time.Instant;
import java.util.UUID;

public record ProviderProfileResponse(
        UUID id,
        UUID userId,
        String businessName,
        String description,
        String location,
        String profileImageUrl,
        UUID categoryId,
        Integer yearsExperience,
        VerificationStatus verificationStatus,
        /** Null (not 0) when the provider has no reviews yet - the app shows "No reviews yet" instead of a 0-star rating. */
        Double averageRating,
        long reviewCount,
        /** True only when the response is for a logged-in customer who favorited this provider - always false on an anonymous browse or a provider's own profile. */
        boolean isFavorited,
        Instant createdAt,
        Instant updatedAt
) {
}
