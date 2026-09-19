package rw.fasha.user;

import jakarta.validation.constraints.NotBlank;

/**
 * What the Flutter app sends to PATCH /api/users/me.
 *
 * Email is deliberately not editable here - it's the user's login
 * identifier, and letting it change without re-verification would be a
 * real security gap for an MVP with no email-verification flow yet.
 */
public record UpdateProfileRequest(

        @NotBlank(message = "Name is required")
        String name,

        String phone
) {
}
