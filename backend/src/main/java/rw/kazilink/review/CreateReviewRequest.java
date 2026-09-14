package rw.kazilink.review;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.Set;

/** What the Flutter app sends to POST /api/bookings/{bookingId}/reviews. */
public record CreateReviewRequest(

        @NotNull(message = "Rating is required")
        @Min(value = 1, message = "Rating must be between 1 and 5")
        @Max(value = 5, message = "Rating must be between 1 and 5")
        Integer rating,

        // Capped - previously unbounded, letting a client send an arbitrarily
        // large comment (storage/abuse concern, not just cosmetic).
        @Size(max = 1000, message = "Comment must be at most 1000 characters")
        String comment,

        Set<ReviewTag> tags
) {
}
