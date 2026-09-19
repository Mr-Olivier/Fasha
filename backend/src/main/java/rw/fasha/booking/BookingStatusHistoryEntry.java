package rw.fasha.booking;

import java.time.Instant;

/** One row of BookingResponse.statusHistory - see BookingStatusHistory. */
public record BookingStatusHistoryEntry(
        BookingStatus status,
        Instant changedAt
) {
}
