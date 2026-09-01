package rw.kazilink.otp;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by OtpService.verifyAndConsume() callers when the submitted code doesn't match, was already used, or expired - deliberately one generic message for all three, so a guesser learns nothing extra. */
public class InvalidOtpException extends ApplicationException {

    public InvalidOtpException() {
        super(HttpStatus.BAD_REQUEST, "That code is invalid or has expired.");
    }
}
