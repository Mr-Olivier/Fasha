package rw.kazilink.common;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.List;

/**
 * @RestControllerAdvice makes every @ExceptionHandler method below apply
 * globally, to every @RestController in the app - one place to turn
 * exceptions into the consistent ApiError JSON shape, instead of repeating
 * try/catch in every controller method.
 *
 * Spring picks the most specific matching handler for whatever exception
 * was thrown, so the order of the methods below doesn't matter.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

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

    /** Catch-all: an unexpected bug should never leak a raw stack trace to the client. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiError.of(HttpStatus.INTERNAL_SERVER_ERROR.value(), "Internal Server Error",
                        "Something went wrong. Please try again."));
    }
}
