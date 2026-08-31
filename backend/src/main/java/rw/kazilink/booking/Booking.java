package rw.kazilink.booking;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * One customer's request to hire a provider for a specific service (maps
 * to the "bookings" table). Plain UUID columns for customerId/
 * providerProfileId/serviceListingId, no @ManyToOne - same reasoning as
 * ServiceListing: we only ever need the id itself here, and BookingService
 * looks up the related name/price fields itself when building a response.
 */
@Entity
@Table(name = "bookings")
@Getter
@Setter
@NoArgsConstructor
public class Booking {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "provider_profile_id", nullable = false)
    private UUID providerProfileId;

    @Column(name = "service_listing_id", nullable = false)
    private UUID serviceListingId;

    /** The customer's own note describing what they need - e.g. "leaking kitchen tap". */
    @Column(columnDefinition = "TEXT")
    private String note;

    /** Optional - a customer may not know an exact date yet and can arrange one with the provider directly. */
    @Column(name = "requested_date")
    private LocalDate requestedDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BookingStatus status = BookingStatus.REQUESTED;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Booking(UUID customerId, UUID providerProfileId, UUID serviceListingId, String note, LocalDate requestedDate) {
        this.customerId = customerId;
        this.providerProfileId = providerProfileId;
        this.serviceListingId = serviceListingId;
        this.note = note;
        this.requestedDate = requestedDate;
        this.status = BookingStatus.REQUESTED;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }
}
