package rw.fasha.booking;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
 * One photo attached to a booking (maps to the "booking_photos" table) -
 * either the customer's evidence of the problem or the provider's proof of
 * the finished work, distinguished by uploaderRole. See
 * SecureFileStorageService for how storagePath is stored/read - it's an
 * opaque path into a private directory the public /uploads/** handler
 * never sees, since these photos are only ever served to the booking's own
 * two parties.
 */
@Entity
@Table(name = "booking_photos")
@Getter
@Setter
@NoArgsConstructor
public class BookingPhoto {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "booking_id", nullable = false)
    private UUID bookingId;

    @Enumerated(EnumType.STRING)
    @Column(name = "uploaded_by_role", nullable = false, length = 20)
    private PhotoUploaderRole uploadedByRole;

    @Column(name = "storage_path", nullable = false, length = 500)
    private String storagePath;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public BookingPhoto(UUID bookingId, PhotoUploaderRole uploadedByRole, String storagePath) {
        this.bookingId = bookingId;
        this.uploadedByRole = uploadedByRole;
        this.storagePath = storagePath;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
