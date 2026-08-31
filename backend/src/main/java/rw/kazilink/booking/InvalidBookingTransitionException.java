package rw.kazilink.booking;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by BookingService when an action doesn't apply to a booking's current status (e.g. accepting an already-COMPLETED booking). */
public class InvalidBookingTransitionException extends ApplicationException {

    public InvalidBookingTransitionException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }
}
