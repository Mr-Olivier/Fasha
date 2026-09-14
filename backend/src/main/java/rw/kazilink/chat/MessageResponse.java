package rw.kazilink.chat;

import java.time.Instant;
import java.util.UUID;

/** senderName lets the client show who said what without a separate lookup; the client compares senderId to its own logged-in id to decide bubble alignment. read is only meaningful on a message the caller sent - it flips to true once the recipient has opened the conversation, powering the ✓✓ read receipt. */
public record MessageResponse(
        UUID id,
        UUID bookingId,
        UUID senderId,
        String senderName,
        String body,
        Instant createdAt,
        boolean read
) {
}
