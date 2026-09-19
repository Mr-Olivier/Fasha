package rw.fasha.user;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by UserService.changePassword() when currentPassword doesn't match what's on file. */
public class IncorrectCurrentPasswordException extends ApplicationException {

    public IncorrectCurrentPasswordException() {
        super(HttpStatus.BAD_REQUEST, "Your current password is incorrect.");
    }
}
