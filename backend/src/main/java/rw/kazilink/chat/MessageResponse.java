package rw.kazilink.chat;

import java.time.Instant;
import java.util.UUID;

/** senderName lets the client show who said what without a separate lookup; the client compares senderId to its own logged-in id to decide bubble alignment. */
public record MessageResponse(
        UUID id,
        UUID bookingId,
        UUID senderId,
        String senderName,
        String body,
        Instant createdAt
) {
}
