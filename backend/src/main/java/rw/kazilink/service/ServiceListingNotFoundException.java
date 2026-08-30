package rw.kazilink.service;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/**
 * Thrown both when a service id truly doesn't exist AND when it exists but
 * belongs to a different provider. Deliberately the same response for
 * both (404, not 403 for the second case) - confirming "this id exists,
 * it's just not yours" would leak information about other providers'
 * services to someone who has no business knowing that.
 */
public class ServiceListingNotFoundException extends ApplicationException {

    public ServiceListingNotFoundException() {
        super(HttpStatus.NOT_FOUND, "Service not found.");
    }
}
