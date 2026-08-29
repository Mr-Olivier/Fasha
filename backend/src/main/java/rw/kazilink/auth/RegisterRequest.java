package rw.kazilink.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import rw.kazilink.user.Role;

/**
 * What the Flutter app sends to POST /api/auth/register, as JSON.
 *
 * The annotations below are Bean Validation rules. Because AuthController
 * marks this parameter @Valid, Spring checks every rule automatically
 * BEFORE our code runs - if any fail, a MethodArgumentNotValidException is
 * thrown and GlobalExceptionHandler turns it into a 400 response. Our
 * service code can then simply assume the data is already well-formed.
 */
public record RegisterRequest(

        @NotBlank(message = "Name is required")
        String name,

        @NotBlank(message = "Email is required")
        @Email(message = "Email must be a valid address")
        String email,

        String phone,

        @NotBlank(message = "Password is required")
        @Size(min = 8, message = "Password must be at least 8 characters long")
        String password,

        // Jackson (Spring's default JSON library) converts the JSON string
        // "CUSTOMER"/"PROVIDER"/"ADMIN" straight into this enum. An unknown
        // value throws HttpMessageNotReadableException, which
        // GlobalExceptionHandler also turns into a clean 400.
        @NotNull(message = "Role is required (CUSTOMER or PROVIDER)")
        Role role
) {
}
