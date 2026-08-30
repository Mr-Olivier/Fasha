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
        Instant createdAt,
        Instant updatedAt
) {
}
