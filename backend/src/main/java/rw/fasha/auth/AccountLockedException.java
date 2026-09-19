package rw.fasha.auth;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by LoginAttemptService when an email has failed login too many times recently - see its Javadoc for the exact threshold/window. */
public class AccountLockedException extends ApplicationException {

    public AccountLockedException(long minutesRemaining) {
        super(HttpStatus.TOO_MANY_REQUESTS,
                "Too many failed login attempts. Try again in " + minutesRemaining + " minute" + (minutesRemaining == 1 ? "" : "s") + ".");
    }
}
