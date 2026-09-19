package rw.fasha.provider;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by GET /api/providers/me before the provider has ever saved a profile. */
public class ProviderProfileNotFoundException extends ApplicationException {

    public ProviderProfileNotFoundException() {
        super(HttpStatus.NOT_FOUND, "You haven't created a provider profile yet.");
    }
}
