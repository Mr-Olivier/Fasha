package rw.kazilink.booking;

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

import java.time.Instant;
import java.util.UUID;

/**
 * One row per status transition a booking has gone through - see
 * V30__create_booking_status_history.sql for why this exists as its own
 * table instead of more timestamp columns on Booking. Written once,
 * immutable, so there's no setter beyond the constructor.
 */
@Entity
@Table(name = "booking_status_history")
@Getter
@NoArgsConstructor
public class BookingStatusHistory {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "booking_id", nullable = false)
    private UUID bookingId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BookingStatus status;

    @Column(name = "changed_at", nullable = false, updatable = false)
    private Instant changedAt;

    public BookingStatusHistory(UUID bookingId, BookingStatus status) {
        this.bookingId = bookingId;
        this.status = status;
    }

    @PrePersist
    void onCreate() {
        this.changedAt = Instant.now();
    }
}
