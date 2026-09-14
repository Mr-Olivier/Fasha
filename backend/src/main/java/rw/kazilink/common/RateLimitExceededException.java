package rw.kazilink.common;

import org.springframework.http.HttpStatus;

/** Thrown by RateLimiter when a caller has exceeded the allowed rate for some action. */
public class RateLimitExceededException extends ApplicationException {

    public RateLimitExceededException() {
        super(HttpStatus.TOO_MANY_REQUESTS, "You're doing that too often - please wait a bit and try again.");
    }
}
