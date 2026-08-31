package rw.kazilink.review;

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
 * A customer's rating (and optional comment) for one completed booking.
 * Plain UUID columns for bookingId/customerId/providerProfileId - same
 * reasoning as every other entity here (Booking, ServiceListing): we only
 * ever need the id itself, never a JPA relationship to navigate.
 */
@Entity
@Table(name = "reviews")
@Getter
@Setter
@NoArgsConstructor
public class Review {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "booking_id", nullable = false, unique = true)
    private UUID bookingId;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "provider_profile_id", nullable = false)
    private UUID providerProfileId;

    @Column(nullable = false)
    private int rating;

    @Column(columnDefinition = "TEXT")
    private String comment;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public Review(UUID bookingId, UUID customerId, UUID providerProfileId, int rating, String comment) {
        this.bookingId = bookingId;
        this.customerId = customerId;
        this.providerProfileId = providerProfileId;
        this.rating = rating;
        this.comment = comment;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
