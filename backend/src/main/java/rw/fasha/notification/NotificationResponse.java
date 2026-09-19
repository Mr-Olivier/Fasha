package rw.fasha.notification;

import java.time.Instant;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        String title,
        String body,
        UUID bookingId,
        boolean read,
        Instant createdAt
) {
    static NotificationResponse from(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getTitle(),
                notification.getBody(),
                notification.getBookingId(),
                notification.isRead(),
                notification.getCreatedAt()
        );
    }
}
