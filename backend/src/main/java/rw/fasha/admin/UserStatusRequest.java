package rw.fasha.admin;

import jakarta.validation.constraints.NotNull;
import rw.fasha.user.UserStatus;

/** Body for PATCH /api/admin/users/{id}/status. */
public record UserStatusRequest(
        @NotNull(message = "status is required")
        UserStatus status
) {
}
