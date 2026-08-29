package rw.kazilink.auth;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by AuthService.register() when the email is already taken. */
public class EmailAlreadyExistsException extends ApplicationException {

    public EmailAlreadyExistsException(String email) {
        super(HttpStatus.CONFLICT, "An account with email '" + email + "' already exists.");
    }
}
