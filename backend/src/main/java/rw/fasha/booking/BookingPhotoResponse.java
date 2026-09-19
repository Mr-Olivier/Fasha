package rw.fasha.booking;

import java.time.Instant;
import java.util.UUID;

/**
 * Metadata only - never the raw storage path (see SecureFileStorageService's
 * doc comment). The actual image bytes are fetched separately via
 * GET /api/bookings/{bookingId}/photos/{id}.
 */
public record BookingPhotoResponse(UUID id, PhotoUploaderRole uploadedByRole, Instant createdAt) {

    public static BookingPhotoResponse from(BookingPhoto photo) {
        return new BookingPhotoResponse(photo.getId(), photo.getUploadedByRole(), photo.getCreatedAt());
    }
}
