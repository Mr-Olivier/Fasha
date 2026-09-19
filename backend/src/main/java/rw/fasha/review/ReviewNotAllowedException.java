package rw.fasha.review;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by ReviewService when a booking can't be reviewed - not COMPLETED yet, or already reviewed. */
public class ReviewNotAllowedException extends ApplicationException {

    public ReviewNotAllowedException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }
}
