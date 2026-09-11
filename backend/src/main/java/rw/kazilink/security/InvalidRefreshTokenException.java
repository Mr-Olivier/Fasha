package rw.kazilink.security;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by RefreshTokenService when a presented refresh token is unknown, expired, or already revoked (including a reused, already-rotated one - see its Javadoc). */
public class InvalidRefreshTokenException extends ApplicationException {

    public InvalidRefreshTokenException() {
        super(HttpStatus.UNAUTHORIZED, "Session expired. Please log in again.");
    }
}
