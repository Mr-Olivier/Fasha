package rw.fasha.chat;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by MessageService.send() when the booking's status doesn't allow contact yet (or anymore) - see BookingStatus.allowsContact(). */
public class MessagingNotAllowedException extends ApplicationException {

    public MessagingNotAllowedException() {
        super(HttpStatus.BAD_REQUEST, "You can only message once the booking has been accepted.");
    }
}
