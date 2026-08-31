package rw.kazilink.auth;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown when a reset token doesn't exist, has expired, or was already used. Same message for all three cases - no reason to help an attacker distinguish them. */
public class InvalidResetTokenException extends ApplicationException {

    public InvalidResetTokenException() {
        super(HttpStatus.BAD_REQUEST, "This reset link is invalid or has expired.");
    }
}
