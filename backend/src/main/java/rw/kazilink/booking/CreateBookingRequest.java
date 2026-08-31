package rw.kazilink.booking;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

/** What the Flutter app sends to POST /api/bookings. */
public record CreateBookingRequest(

        @NotNull(message = "serviceListingId is required")
        UUID serviceListingId,

        String note,

        LocalDate requestedDate
) {
}
