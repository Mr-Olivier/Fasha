package rw.fasha.admin;

import rw.fasha.user.Role;
import rw.fasha.user.UserStatus;

import java.time.Instant;
import java.util.UUID;

/** One row in the admin Customers/Providers account list (GET /api/admin/users). */
public record AdminUserResponse(
        UUID userId,
        String name,
        String email,
        String phone,
        Role role,
        UserStatus status,
        String profileImageUrl,
        Instant createdAt
) {
}
