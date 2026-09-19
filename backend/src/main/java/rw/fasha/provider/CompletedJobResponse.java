package rw.fasha.provider;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** One row on D8's completed-jobs list - a completed booking, with its review (if any) already attached. */
public record CompletedJobResponse(
        UUID bookingId,
        UUID customerId,
        String customerName,
        String serviceName,
        BigDecimal price,
        Instant completedAt,
        Integer rating,
        String reviewComment,
        boolean hasReview
) {
}
