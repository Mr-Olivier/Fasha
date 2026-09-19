package rw.fasha.booking;

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

import java.math.BigDecimal;
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

    /** Where the job is - optional, same reasoning as requestedDate. */
    @Column
    private String address;

    /** Rough time of day the customer prefers, e.g. MORNING - optional. */
    @Enumerated(EnumType.STRING)
    @Column(name = "time_window", length = 20)
    private TimeWindow timeWindow;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BookingStatus status = BookingStatus.REQUESTED;

    /**
     * The service's price at the moment this booking was created - see
     * V23__add_price_snapshot_and_work_note_to_bookings.sql's doc comment
     * for why this is snapshotted rather than always looked up live.
     */
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    /** A short note the provider leaves when finishing the job - shown to the customer. */
    @Column(name = "work_note", columnDefinition = "TEXT")
    private String workNote;

    /** Why the customer cancelled, if they said - optional, set only by BookingService.cancel(). */
    @Column(name = "cancellation_reason", columnDefinition = "TEXT")
    private String cancellationReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Booking(
            UUID customerId,
            UUID providerProfileId,
            UUID serviceListingId,
            String note,
            LocalDate requestedDate,
            String address,
            TimeWindow timeWindow
    ) {
        this.customerId = customerId;
        this.providerProfileId = providerProfileId;
        this.serviceListingId = serviceListingId;
        this.note = note;
        this.requestedDate = requestedDate;
        this.address = address;
        this.timeWindow = timeWindow;
        this.status = BookingStatus.REQUESTED;
    }

    public Booking(
            UUID customerId,
            UUID providerProfileId,
            UUID serviceListingId,
            String note,
            LocalDate requestedDate,
            String address,
            TimeWindow timeWindow,
            BigDecimal price
    ) {
        this(customerId, providerProfileId, serviceListingId, note, requestedDate, address, timeWindow);
        this.price = price;
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
