package rw.fasha.auth;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/**
 * Thrown when someone tries to self-register as ADMIN. Per README.md
 * section 13, administrators are a trusted role that must be created some
 * other way (e.g. directly in the database, or a future admin-only
 * endpoint) - never through the public registration form.
 */
public class InvalidRegistrationRoleException extends ApplicationException {

    public InvalidRegistrationRoleException() {
        super(HttpStatus.BAD_REQUEST, "Cannot self-register as ADMIN.");
    }
}
