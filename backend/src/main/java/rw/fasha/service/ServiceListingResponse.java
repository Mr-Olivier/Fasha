package rw.fasha.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ServiceListingResponse(
        UUID id,
        UUID providerProfileId,
        UUID categoryId,
        String name,
        String description,
        BigDecimal price,
        ServiceDuration duration,
        boolean visible,
        Instant createdAt
) {

    public static ServiceListingResponse from(ServiceListing listing) {
        return new ServiceListingResponse(
                listing.getId(),
                listing.getProviderProfileId(),
                listing.getCategoryId(),
                listing.getName(),
                listing.getDescription(),
                listing.getPrice(),
                listing.getDuration(),
                listing.isVisible(),
                listing.getCreatedAt()
        );
    }
}
