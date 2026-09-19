package rw.fasha.booking;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

/** What the Flutter app sends to POST /api/bookings. */
public record CreateBookingRequest(

        @NotNull(message = "serviceListingId is required")
        UUID serviceListingId,

        @Size(max = 500, message = "note must be at most 500 characters")
        String note,

        LocalDate requestedDate,

        @Size(max = 255, message = "address must be at most 255 characters")
        String address,

        TimeWindow timeWindow
) {
}
