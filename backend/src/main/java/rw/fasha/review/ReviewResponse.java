package rw.fasha.review;

import java.time.Instant;
import java.util.Set;
import java.util.UUID;

/**
 * What the app gets back for a review. Includes the denormalized
 * customerName - same reasoning as BookingResponse - so a provider's
 * review list can render "Alice says..." without a separate round-trip
 * per review.
 */
public record ReviewResponse(
        UUID id,
        UUID bookingId,
        UUID customerId,
        String customerName,
        int rating,
        String comment,
        Set<ReviewTag> tags,
        Instant createdAt
) {
}
