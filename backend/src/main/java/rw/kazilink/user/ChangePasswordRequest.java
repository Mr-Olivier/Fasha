package rw.kazilink.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * What the Flutter app sends to PUT /api/users/me/password.
 *
 * Unlike ResetPasswordRequest (auth package), this is for a user who's
 * ALREADY logged in and simply wants to change their password from
 * settings - so it requires the current password instead of a reset token,
 * proving it's really them even though their session is already trusted.
 */
public record ChangePasswordRequest(

        @NotBlank(message = "Current password is required")
        String currentPassword,

        @NotBlank(message = "New password is required")
        @Size(min = 8, message = "New password must be at least 8 characters long")
        String newPassword
) {
}
