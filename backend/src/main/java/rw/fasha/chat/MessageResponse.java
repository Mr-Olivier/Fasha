package rw.fasha.chat;

import java.time.Instant;
import java.util.UUID;

/**
 * senderName lets the client show who said what without a separate lookup;
 * the client compares senderId to its own logged-in id to decide bubble
 * alignment. read is only meaningful on a message the caller sent - it
 * flips to true once the recipient has opened the conversation, powering
 * the ✓✓ read receipt.
 *
 * body is null for an attachment-only message. attachmentType is null for
 * a text-only one; when it's non-null, the client fetches the actual file
 * from GET /api/bookings/{bookingId}/messages/{id}/attachment - this
 * response never carries a raw file path, same "opaque to the client"
 * reasoning as BookingPhotoResponse.
 */
public record MessageResponse(
        UUID id,
        UUID bookingId,
        UUID senderId,
        String senderName,
        String body,
        MessageAttachmentType attachmentType,
        Instant createdAt,
        boolean read
) {
}
