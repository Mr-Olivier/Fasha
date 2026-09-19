package rw.fasha.security;

import tools.jackson.databind.ObjectMapper; // Jackson 3 (Spring Boot 4) - not com.fasterxml.jackson
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;
import rw.fasha.common.ApiError;

import java.io.IOException;

/**
 * Counterpart to RestAuthenticationEntryPoint: this fires when the caller
 * IS authenticated (their token is valid) but their role doesn't have
 * permission - e.g. a CUSTOMER hitting a PROVIDER-only endpoint via a
 * future @PreAuthorize("hasRole('PROVIDER')"). Kept as a proper 403 with
 * our normal ApiError JSON shape, instead of Spring Security's empty body.
 */
@Component
@RequiredArgsConstructor
public class RestAccessDeniedHandler implements AccessDeniedHandler {

    private final ObjectMapper objectMapper;

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException)
            throws IOException {
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        ApiError body = ApiError.of(
                HttpStatus.FORBIDDEN.value(),
                "Forbidden",
                "You do not have permission to access this resource."
        );
        objectMapper.writeValue(response.getWriter(), body);
    }
}
