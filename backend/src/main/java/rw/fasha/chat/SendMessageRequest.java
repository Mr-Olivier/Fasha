package rw.fasha.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Body for POST /api/bookings/{bookingId}/messages. */
public record SendMessageRequest(
        @NotBlank(message = "body is required")
        @Size(max = 2000, message = "body must be at most 2000 characters")
        String body
) {
}
