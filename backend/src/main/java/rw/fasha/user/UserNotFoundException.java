package rw.fasha.user;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/**
 * Thrown when a userId taken from an already-verified JWT no longer
 * matches a row in the database - practically only possible if the
 * account was deleted after the token was issued. Not a client mistake,
 * but still needs a clean response rather than an unchecked
 * NoSuchElementException from Optional.get().
 */
public class UserNotFoundException extends ApplicationException {

    public UserNotFoundException() {
        super(HttpStatus.NOT_FOUND, "Account not found.");
    }
}
