package rw.kazilink.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

/**
 * Runs once for every incoming HTTP request (that's what OncePerRequestFilter
 * guarantees - some servlet containers would otherwise run a filter twice
 * for the same request in edge cases like forwards).
 *
 * If it finds a valid "Authorization: Bearer <token>" header, it tells
 * Spring Security who's calling: their user id becomes the "principal", and
 * their role becomes a granted authority. Every controller/service can then
 * trust SecurityContextHolder, and @PreAuthorize("hasRole('PROVIDER')")
 * annotations (added on later endpoints) work automatically - all without
 * touching the database on this request.
 *
 * If there's no token, or it's invalid, we do nothing and move on -
 * SecurityConfig decides afterwards whether the requested endpoint is
 * public or requires authentication, and rejects it with 401 if needed.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String AUTH_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        String header = request.getHeader(AUTH_HEADER);

        if (header != null && header.startsWith(BEARER_PREFIX)) {
            String token = header.substring(BEARER_PREFIX.length());
            try {
                UUID userId = jwtService.extractUserId(token);
                String role = jwtService.extractRole(token);

                // Spring Security's convention is that role-based checks
                // (hasRole("PROVIDER")) look for an authority named "ROLE_PROVIDER".
                var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + role));
                var authentication = new UsernamePasswordAuthenticationToken(userId, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (JwtException | IllegalArgumentException expiredOrInvalidToken) {
                // Token was expired, tampered with, or malformed. Leave the
                // request unauthenticated rather than throwing here -
                // SecurityConfig's authorizeHttpRequests rules are what
                // actually decide whether that's a problem for this endpoint.
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }
}
