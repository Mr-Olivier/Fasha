package rw.fasha.security;

import tools.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;
import rw.fasha.common.ApiError;

import java.io.IOException;

/**
 * Without this, Spring Security's built-in default responds with a bare
 * 403 and no body whenever a request has no token (or an invalid one) -
 * indistinguishable from "you're logged in but not allowed". This class
 * makes that case a proper 401 with our normal ApiError JSON shape, so the
 * Flutter app can tell "please log in" (401) apart from "you don't have
 * permission" (403, see RestAccessDeniedHandler) and react differently.
 *
 * Note the import above: Spring Boot 4 moved to Jackson 3, which renamed
 * its Java package from "com.fasterxml.jackson" to "tools.jackson" - easy
 * to trip over if you're used to older Spring Boot/Jackson 2 tutorials.
 */
@Component
@RequiredArgsConstructor
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper;

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException)
            throws IOException {
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        ApiError body = ApiError.of(
                HttpStatus.UNAUTHORIZED.value(),
                "Unauthorized",
                "Authentication is required to access this resource."
        );
        objectMapper.writeValue(response.getWriter(), body);
    }
}
