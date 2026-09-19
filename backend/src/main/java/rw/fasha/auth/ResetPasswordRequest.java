package rw.fasha.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Identifies which pending reset to spend by (email, code) rather than an opaque token - see AuthService.forgotPassword's Javadoc for why the code now only ever reaches the user by email. */
public record ResetPasswordRequest(

        @NotBlank(message = "Email is required")
        @Email(message = "Email must be a valid address")
        String email,

        @NotBlank(message = "Code is required")
        String code,

        @NotBlank(message = "Password is required")
        @Size(min = 8, message = "Password must be at least 8 characters long")
        String newPassword
) {
}
