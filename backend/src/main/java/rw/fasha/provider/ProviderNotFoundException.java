package rw.fasha.provider;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/**
 * Thrown by the PUBLIC GET /api/providers/{id} when that id doesn't exist,
 * or belongs to a provider who isn't APPROVED. Deliberately a different
 * exception from ProviderProfileNotFoundException - that one's message
 * ("You haven't created a provider profile yet.") makes sense for a
 * provider looking up their OWN profile, not a customer browsing someone
 * else's.
 */
public class ProviderNotFoundException extends ApplicationException {

    public ProviderNotFoundException() {
        super(HttpStatus.NOT_FOUND, "Provider not found.");
    }
}
