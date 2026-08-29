package rw.kazilink.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Covers the filter's three possible outcomes for an incoming request:
 * no/garbage token (unauthenticated, request still proceeds),
 * a valid non-revoked token (authenticated), and a valid but REVOKED token
 * (unauthenticated - the whole point of adding logout).
 *
 * We never assert on the HTTP response here: this filter never rejects a
 * request itself, it only sets or clears SecurityContextHolder - whether
 * that then causes a 401 is SecurityConfig's job, not this class's.
 */
@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {

    @Mock
    private JwtService jwtService;

    @Mock
    private RevokedTokenRepository revokedTokenRepository;

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @InjectMocks
    private JwtAuthenticationFilter filter;

    @BeforeEach
    @AfterEach
    void clearSecurityContext() {
        // SecurityContextHolder is a ThreadLocal, so it leaks between tests
        // unless we reset it both before and after each one.
        SecurityContextHolder.clearContext();
    }

    @Test
    void noAuthorizationHeader_leavesRequestUnauthenticated() throws Exception {
        when(request.getHeader("Authorization")).thenReturn(null);

        filter.doFilter(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void validNonRevokedToken_authenticatesTheRequest() throws Exception {
        UUID userId = UUID.randomUUID();
        UUID jti = UUID.randomUUID();
        when(request.getHeader("Authorization")).thenReturn("Bearer valid-token");
        when(jwtService.extractJti("valid-token")).thenReturn(jti);
        when(revokedTokenRepository.existsById(jti)).thenReturn(false);
        when(jwtService.extractUserId("valid-token")).thenReturn(userId);
        when(jwtService.extractRole("valid-token")).thenReturn("CUSTOMER");

        filter.doFilter(request, response, filterChain);

        var authentication = SecurityContextHolder.getContext().getAuthentication();
        assertThat(authentication).isNotNull();
        assertThat(authentication.getPrincipal()).isEqualTo(userId);
        assertThat(authentication.getAuthorities()).extracting(Object::toString).containsExactly("ROLE_CUSTOMER");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void revokedToken_leavesRequestUnauthenticated() throws Exception {
        UUID jti = UUID.randomUUID();
        when(request.getHeader("Authorization")).thenReturn("Bearer logged-out-token");
        when(jwtService.extractJti("logged-out-token")).thenReturn(jti);
        when(revokedTokenRepository.existsById(jti)).thenReturn(true);

        filter.doFilter(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        // The request still proceeds down the chain - SecurityConfig is what
        // turns "unauthenticated" into an actual 401 response.
        verify(filterChain).doFilter(request, response);
    }
}
