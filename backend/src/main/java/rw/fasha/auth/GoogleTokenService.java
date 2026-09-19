package rw.fasha.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;

/**
 * Verifies a Google ID token against Google's own public keys (fetched and
 * cached internally by GoogleIdTokenVerifier) - this is what actually
 * confirms "this token was really issued by Google, for THIS app, and
 * hasn't expired", not just that it's well-formed JSON.
 *
 * The verifier is built lazily, once, the first time it's needed, rather
 * than at startup - so a backend with GOOGLE_OAUTH_CLIENT_ID unset still
 * starts up fine and serves every other endpoint; only an actual Google
 * sign-in attempt fails, with a clear GoogleSignInNotConfiguredException.
 */
@Service
public class GoogleTokenService {

    @Value("${app.google.client-id:}")
    private String clientId;

    private volatile GoogleIdTokenVerifier verifier;

    /** @return the verified token's payload (email, name, "sub", ...). */
    public GoogleIdToken.Payload verify(String idToken) {
        GoogleIdTokenVerifier verifier = getOrBuildVerifier();

        GoogleIdToken token;
        try {
            token = verifier.verify(idToken);
        } catch (GeneralSecurityException | IOException | IllegalArgumentException e) {
            throw new GoogleTokenVerificationException();
        }

        if (token == null) {
            throw new GoogleTokenVerificationException();
        }
        return token.getPayload();
    }

    private GoogleIdTokenVerifier getOrBuildVerifier() {
        GoogleIdTokenVerifier existing = verifier;
        if (existing != null) {
            return existing;
        }
        if (clientId == null || clientId.isBlank()) {
            throw new GoogleSignInNotConfiguredException();
        }

        synchronized (this) {
            if (verifier == null) {
                verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), GsonFactory.getDefaultInstance())
                        .setAudience(Collections.singletonList(clientId))
                        .build();
            }
            return verifier;
        }
    }
}
