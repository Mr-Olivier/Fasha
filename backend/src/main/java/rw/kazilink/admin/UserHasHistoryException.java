package rw.kazilink.admin;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by AdminUserService.delete() when the account has booking history - deleting it would either orphan that history or silently destroy it, so suspension is the only option instead (see AdminUserService's doc comment). */
public class UserHasHistoryException extends ApplicationException {

    public UserHasHistoryException() {
        super(HttpStatus.CONFLICT, "This account has booking history and can't be deleted - suspend it instead.");
    }
}
