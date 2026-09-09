package rw.kazilink.auth;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/**
 * Thrown when GOOGLE_OAUTH_CLIENT_ID isn't set on this backend (see
 * application.yml's app.google.client-id). Kept separate from
 * GoogleTokenVerificationException so a missing-config mistake shows up
 * clearly in logs/responses instead of looking like a bad token from the
 * client.
 */
public class GoogleSignInNotConfiguredException extends ApplicationException {

    public GoogleSignInNotConfiguredException() {
        super(HttpStatus.SERVICE_UNAVAILABLE, "Google sign-in is not configured on this server yet.");
    }
}
