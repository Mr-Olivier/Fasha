package rw.kazilink.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.List;

/**
 * @RestControllerAdvice makes every @ExceptionHandler method below apply
 * globally, to every @RestController in the app - one place to turn
 * exceptions into the consistent ApiError JSON shape, instead of repeating
 * try/catch in every controller method.
 *
 * Spring picks the most specific matching handler for whatever exception
 * was thrown (NoResourceFoundException before the generic Exception
 * catch-all, for example), so the order of the methods below doesn't matter.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** Thrown deliberately by our own service layer, e.g. EmailAlreadyExistsException. */
    @ExceptionHandler(ApplicationException.class)
    public ResponseEntity<ApiError> handleApplicationException(ApplicationException ex) {
        return ResponseEntity.status(ex.getStatus())
                .body(ApiError.of(ex.getStatus().value(), ex.getStatus().getReasonPhrase(), ex.getMessage()));
    }

    /** Thrown automatically when a @Valid request body fails a Bean Validation rule (@NotBlank, @Email, ...). */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        List<String> details = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .toList();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiError.of(HttpStatus.BAD_REQUEST.value(), "Bad Request", "Validation failed.", details));
    }

    /** Thrown when the request body isn't valid JSON, or an enum field (e.g. "role") has an unknown value. */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> handleUnreadable(HttpMessageNotReadableException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiError.of(HttpStatus.BAD_REQUEST.value(), "Bad Request",
                        "Request body is malformed or contains an invalid value."));
    }

    /**
     * Thrown when no controller matches the requested path (a genuine
     * "URL doesn't exist", e.g. a typo or an endpoint we haven't built yet)
     * AND it doesn't match a static resource either. Without this handler,
     * it would fall through to the generic 500 below - a wrong-but-common
     * mistake, since a missing ROUTE isn't a server BUG.
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(NoResourceFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiError.of(HttpStatus.NOT_FOUND.value(), "Not Found", "No such endpoint."));
    }

    /**
     * Catch-all: an unexpected bug should never leak a raw stack trace to
     * the client - but it MUST be logged, or a real bug becomes invisible
     * on the server too. (This bit us during development: this handler
     * originally had no logging, so an unrelated bug printed nothing at all.)
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiError.of(HttpStatus.INTERNAL_SERVER_ERROR.value(), "Internal Server Error",
                        "Something went wrong. Please try again."));
    }
}
