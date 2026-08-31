package rw.kazilink.notification;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * One in-app notification for one user (maps to the "notifications" table).
 * Created server-side whenever something happens that the recipient didn't
 * cause themselves - a provider accepting/rejecting/starting/completing a
 * booking (customer is notified), a customer creating or cancelling one
 * (provider is notified), or an admin approving/rejecting a provider
 * application. There's no push notification wiring (no FCM/APNs) - the app
 * just polls GET /api/notifications, same as every other list screen here.
 */
@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
public class Notification {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, length = 500)
    private String body;

    /** Null for notifications not about a specific booking (e.g. a provider approval decision). */
    @Column(name = "booking_id")
    private UUID bookingId;

    @Column(name = "is_read", nullable = false)
    private boolean read = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public Notification(UUID userId, String title, String body, UUID bookingId) {
        this.userId = userId;
        this.title = title;
        this.body = body;
        this.bookingId = bookingId;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
