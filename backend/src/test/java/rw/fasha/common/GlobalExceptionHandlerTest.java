package rw.fasha.common;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.authorization.AuthorizationDecision;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Documents the exact HTTP status each exception type maps to. Added after
 * a real bug: @PreAuthorize denials (AuthorizationDeniedException) were
 * falling through to the generic 500 handler instead of the dedicated 403
 * one, because Spring MVC resolves @ExceptionHandler methods in DECLARATION
 * order of specificity, and there was no specific handler for it yet.
 */
class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void applicationException_mapsToItsOwnStatus() {
        var ex = new ApplicationException(HttpStatus.CONFLICT, "already exists") {
        };

        var response = handler.handleApplicationException(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody().message()).isEqualTo("already exists");
    }

    @Test
    void authorizationDeniedException_mapsTo403NotTheGeneric500() {
        var ex = new AuthorizationDeniedException("denied", new AuthorizationDecision(false));

        var response = handler.handleAuthorizationDenied(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void noResourceFoundException_mapsTo404NotTheGeneric500() {
        var ex = new NoResourceFoundException(org.springframework.http.HttpMethod.GET, "/no/such/path", null);

        var response = handler.handleNotFound(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void unexpectedException_mapsTo500() {
        var response = handler.handleUnexpected(new RuntimeException("boom"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
