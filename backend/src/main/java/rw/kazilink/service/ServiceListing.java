package rw.kazilink.service;

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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * One service a provider offers (maps to the "services" table). Named
 * ServiceListing, not the bare "Service" from README.md's entity list -
 * that name would collide with Spring's own @Service annotation
 * (org.springframework.stereotype.Service) the moment both need importing
 * in the same file, e.g. this entity's own service-layer class.
 *
 * Plain UUID columns for providerProfileId/categoryId, no @ManyToOne -
 * same reasoning as ProviderProfile.userId: we only ever need the id
 * itself here, never to navigate to the related entity's other fields.
 */
@Entity
@Table(name = "services")
@Getter
@Setter
@NoArgsConstructor
public class ServiceListing {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "provider_profile_id", nullable = false)
    private UUID providerProfileId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ServiceDuration duration = ServiceDuration.ONE_TO_TWO_HOURS;

    /** Whether this service shows up in customer-facing browse/search - see V22's doc comment. */
    @Column(name = "is_visible", nullable = false)
    private boolean visible = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public ServiceListing(UUID providerProfileId, UUID categoryId, String name, String description, BigDecimal price) {
        this.providerProfileId = providerProfileId;
        this.categoryId = categoryId;
        this.name = name;
        this.description = description;
        this.price = price;
    }

    public ServiceListing(
            UUID providerProfileId,
            UUID categoryId,
            String name,
            String description,
            BigDecimal price,
            ServiceDuration duration,
            boolean visible
    ) {
        this(providerProfileId, categoryId, name, description, price);
        this.duration = duration;
        this.visible = visible;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
