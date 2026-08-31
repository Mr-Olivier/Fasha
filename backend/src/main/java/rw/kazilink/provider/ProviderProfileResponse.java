package rw.kazilink.provider;

import java.time.Instant;
import java.util.UUID;

public record ProviderProfileResponse(
        UUID id,
        UUID userId,
        String businessName,
        String description,
        String location,
        String profileImageUrl,
        VerificationStatus verificationStatus,
        /** Null (not 0) when the provider has no reviews yet - the app shows "No reviews yet" instead of a 0-star rating. */
        Double averageRating,
        long reviewCount,
        Instant createdAt,
        Instant updatedAt
) {
}
