package rw.fasha.notification;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

public class NotificationNotFoundException extends ApplicationException {

    public NotificationNotFoundException() {
        super(HttpStatus.NOT_FOUND, "Notification not found.");
    }
}
