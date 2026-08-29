package rw.kazilink.auth;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/**
 * Thrown by AuthService.login() for either "email not found" OR "wrong
 * password". Using one exception (and one generic message) for both cases
 * is deliberate: telling an attacker "that email doesn't exist" vs "wrong
 * password" leaks which emails are registered.
 */
public class InvalidCredentialsException extends ApplicationException {

    public InvalidCredentialsException() {
        super(HttpStatus.UNAUTHORIZED, "Invalid email or password.");
    }
}
