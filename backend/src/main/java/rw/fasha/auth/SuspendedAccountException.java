package rw.fasha.auth;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/**
 * Thrown by AuthService.login() when the password is correct but an admin
 * has set this account's status to SUSPENDED (README.md section 3).
 * Unlike InvalidCredentialsException, it's fine to be specific here - the
 * user already proved they own the account by entering the right password.
 */
public class SuspendedAccountException extends ApplicationException {

    public SuspendedAccountException() {
        super(HttpStatus.FORBIDDEN, "This account has been suspended. Contact support for help.");
    }
}
