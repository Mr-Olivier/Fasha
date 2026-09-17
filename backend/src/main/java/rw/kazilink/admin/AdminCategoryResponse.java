package rw.kazilink.admin;

import java.util.UUID;

/**
 * The admin category list's richer shape - unlike the public CategoryResponse
 * (just id/name/description), this also carries what an admin needs to
 * decide whether a category is pulling its weight: how many APPROVED
 * providers actually offer something in it, how many bookings it has ever
 * generated, and whether it's currently hidden from customers.
 */
public record AdminCategoryResponse(
        UUID id,
        String name,
        String description,
        boolean active,
        long providerCount,
        long bookingCount,
        String imageUrl
) {
}
