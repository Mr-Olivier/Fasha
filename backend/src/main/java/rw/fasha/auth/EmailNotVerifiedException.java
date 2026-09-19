package rw.fasha.auth;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by AuthService.login() when the password is correct but the account's email was never verified - same "fine to be specific" reasoning as SuspendedAccountException, since the caller already proved they own the account. */
public class EmailNotVerifiedException extends ApplicationException {

    public EmailNotVerifiedException() {
        super(HttpStatus.FORBIDDEN, "Please verify your email before logging in.");
    }
}
