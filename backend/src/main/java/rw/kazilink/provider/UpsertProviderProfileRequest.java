package rw.kazilink.provider;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * Body for PUT /api/providers/me. Deliberately has no verificationStatus
 * field - see VerificationStatus's Javadoc for why that's never settable
 * by the provider themselves.
 */
public record UpsertProviderProfileRequest(

        @NotBlank(message = "Business name is required")
        @Size(max = 150, message = "Business name must be at most 150 characters")
        String businessName,

        @Size(max = 2000, message = "Description must be at most 2000 characters")
        String description,

        @Size(max = 150, message = "Location must be at most 150 characters")
        String location,

        String profileImageUrl,

        /** Optional - which category this business mainly belongs to. */
        UUID categoryId,

        @Min(value = 0, message = "Years of experience can't be negative")
        Integer yearsExperience
) {
}
