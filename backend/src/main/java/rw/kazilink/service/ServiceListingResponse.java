package rw.kazilink.service;

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
        Instant createdAt
) {
}
