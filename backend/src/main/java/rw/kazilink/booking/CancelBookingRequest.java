package rw.kazilink.booking;

import jakarta.validation.constraints.Size;

/** Body for PATCH /api/bookings/{id}/cancel - the reason is optional, matching the Cancel Confirmation screen. */
public record CancelBookingRequest(
        @Size(max = 500, message = "reason must be at most 500 characters")
        String reason
) {
}
