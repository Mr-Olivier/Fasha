package rw.kazilink.user;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by UserService.changePassword() when currentPassword doesn't match what's on file. */
public class IncorrectCurrentPasswordException extends ApplicationException {

    public IncorrectCurrentPasswordException() {
        super(HttpStatus.BAD_REQUEST, "Your current password is incorrect.");
    }
}
