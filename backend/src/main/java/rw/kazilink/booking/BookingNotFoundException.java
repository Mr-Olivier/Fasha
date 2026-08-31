package rw.kazilink.booking;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/**
 * Thrown both when a booking id genuinely doesn't exist AND when it exists
 * but doesn't belong to the caller - same "don't reveal what you can't
 * touch" reasoning as ServiceListingNotFoundException. A customer probing
 * random ids can't learn whether a booking exists, only that they can't
 * see it.
 */
public class BookingNotFoundException extends ApplicationException {

    public BookingNotFoundException() {
        super(HttpStatus.NOT_FOUND, "Booking not found.");
    }
}
