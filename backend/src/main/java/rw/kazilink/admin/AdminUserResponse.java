package rw.kazilink.admin;

import rw.kazilink.user.Role;
import rw.kazilink.user.UserStatus;

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
