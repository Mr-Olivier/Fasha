package rw.fasha.common;

import org.springframework.http.HttpStatus;

/**
 * Base class for business-rule errors we throw ON PURPOSE - "email already
 * registered", "invalid password", "booking already accepted" - as opposed
 * to unexpected bugs (NullPointerException, a broken database connection).
 *
 * Each subclass (one per specific error, e.g. EmailAlreadyExistsException)
 * says which HTTP status it maps to. GlobalExceptionHandler catches this
 * base class, so it can turn ANY subclass into a clean ApiError without
 * needing an if/else per exception type.
 */
public abstract class ApplicationException extends RuntimeException {

    private final HttpStatus status;

    protected ApplicationException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
