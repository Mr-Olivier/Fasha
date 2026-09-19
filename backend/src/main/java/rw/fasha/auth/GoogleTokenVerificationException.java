package rw.fasha.auth;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/**
 * Thrown when the Google ID token the app sent is missing, expired,
 * forged, issued for a different app (wrong audience), or belongs to a
 * Google account whose email Google itself hasn't verified - see
 * GoogleTokenService.verify() and AuthService.googleAuth().
 */
public class GoogleTokenVerificationException extends ApplicationException {

    public GoogleTokenVerificationException() {
        super(HttpStatus.UNAUTHORIZED, "Could not verify this Google sign-in. Please try again.");
    }
}
