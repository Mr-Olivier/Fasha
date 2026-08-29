package rw.kazilink.common;

import java.time.Instant;
import java.util.List;

/**
 * The single, consistent JSON shape every error response from this API
 * takes - a validation failure, a business error like "email already
 * exists", and an unexpected bug all come back looking like this. The
 * Flutter app only ever needs to know how to parse ONE error shape.
 *
 * This is a Java "record": a concise way to declare an immutable class
 * that's just a bundle of fields, with constructor/getters/equals/
 * hashCode/toString generated for you. Perfect fit for a DTO like this.
 */
public record ApiError(
        Instant timestamp,
        int status,
        String error,
        String message,
        List<String> details
) {

    public static ApiError of(int status, String error, String message) {
        return new ApiError(Instant.now(), status, error, message, List.of());
    }

    public static ApiError of(int status, String error, String message, List<String> details) {
        return new ApiError(Instant.now(), status, error, message, details);
    }
}
