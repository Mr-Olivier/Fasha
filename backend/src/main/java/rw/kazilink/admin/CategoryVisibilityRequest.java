package rw.kazilink.admin;

import jakarta.validation.constraints.NotNull;

/** Body for PATCH /api/admin/categories/{id}/visibility - true shows the category to customers, false hides it. */
public record CategoryVisibilityRequest(
        @NotNull(message = "active is required")
        Boolean active
) {
}
