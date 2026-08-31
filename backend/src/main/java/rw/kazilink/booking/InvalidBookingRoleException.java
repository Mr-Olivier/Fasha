package rw.kazilink.booking;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown when GET /api/bookings's ?role= query param is anything other than "customer" or "provider". */
public class InvalidBookingRoleException extends ApplicationException {

    public InvalidBookingRoleException() {
        super(HttpStatus.BAD_REQUEST, "role must be \"customer\" or \"provider\".");
    }
}
