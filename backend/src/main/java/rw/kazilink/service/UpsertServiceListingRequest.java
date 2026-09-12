package rw.kazilink.service;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.UUID;

/** Body for both POST (create) and PUT (edit) - same shape either way, so one DTO covers both. */
public record UpsertServiceListingRequest(

        @NotNull(message = "Category is required")
        UUID categoryId,

        @NotBlank(message = "Name is required")
        @Size(max = 150, message = "Name must be at most 150 characters")
        String name,

        @Size(max = 2000, message = "Description must be at most 2000 characters")
        String description,

        @NotNull(message = "Price is required")
        @DecimalMin(value = "0", message = "Price cannot be negative")
        BigDecimal price,

        @NotNull(message = "Duration is required")
        ServiceDuration duration,

        boolean visible
) {
}
