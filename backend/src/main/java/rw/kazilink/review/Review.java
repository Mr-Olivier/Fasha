package rw.kazilink.review;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.EnumSet;
import java.util.Set;
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

    /** "What stood out" - see V31__create_review_tags.sql. Eager: always shown alongside the review, never worth a second query. */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "review_tags", joinColumns = @JoinColumn(name = "review_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "tag")
    private Set<ReviewTag> tags = EnumSet.noneOf(ReviewTag.class);

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public Review(UUID bookingId, UUID customerId, UUID providerProfileId, int rating, String comment, Set<ReviewTag> tags) {
        this.bookingId = bookingId;
        this.customerId = customerId;
        this.providerProfileId = providerProfileId;
        this.rating = rating;
        this.comment = comment;
        this.tags = tags == null ? EnumSet.noneOf(ReviewTag.class) : tags;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
