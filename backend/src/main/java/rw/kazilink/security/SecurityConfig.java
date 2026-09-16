package rw.kazilink.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.http.HttpMethod;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Wires Spring Security for a stateless, JWT-only API - no login pages, no
 * HTTP sessions, no cookies. Every request must carry its own token.
 *
 * {@code @EnableMethodSecurity} turns on @PreAuthorize("hasRole('PROVIDER')")
 * style annotations directly on controller/service methods - we don't use
 * any yet, but every protected endpoint from Feature 3 onward will.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final RestAuthenticationEntryPoint restAuthenticationEntryPoint;
    private final RestAccessDeniedHandler restAccessDeniedHandler;

    /**
     * BCrypt is a one-way hash designed to be deliberately slow, so
     * brute-forcing leaked password hashes is impractical. We NEVER store
     * a plain-text password - only what this encoder produces.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Only relevant for the Flutter WEB target (Chrome, Edge, ...) - native
     * mobile/desktop builds don't send an Origin header at all, so this
     * never affects them. Without it, the browser's own CORS policy
     * silently discards every response from this API before our Dart code
     * ever sees it, even though the server answered with a normal 200 -
     * curl (which ignores CORS entirely) won't reveal this; only an actual
     * browser will. Flutter web's dev/debug port changes across runs, so we
     * allow any localhost/127.0.0.1 port rather than hardcoding one. The
     * 192.168.x.x and 10.x.x.x patterns are for testing a second device (a
     * phone) on the same Wi-Fi against this same backend - see
     * AppConfig.apiBaseUrl.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of(
                "http://localhost:*", "http://127.0.0.1:*", "http://192.168.*.*:*", "http://10.*.*.*:*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(Customizer.withDefaults())
                // Defense-in-depth response headers - meaningful even for a
                // JSON API, since anything served under this origin (including
                // the public /uploads/** avatar images and any error page)
                // benefits from them. X-Content-Type-Options and X-Frame-Options
                // are already ON by Spring Security's own defaults; the three
                // below are NOT, so they're spelled out explicitly.
                .headers(headers -> headers
                        // 'none' is safe for a pure JSON API that serves no HTML of
                        // its own to render - the only non-JSON responses are
                        // static avatar images, which don't execute scripts anyway.
                        .contentSecurityPolicy(csp -> csp.policyDirectives("default-src 'none'; frame-ancestors 'none'"))
                        // Tells browsers to only ever talk to this host over HTTPS
                        // from now on, even if a link/redirect somehow says HTTP -
                        // closes the window for a downgrade attack on a real
                        // deployment. Harmless on this machine's local HTTP dev
                        // server: browsers don't act on it for plain HTTP responses.
                        .httpStrictTransportSecurity(hsts -> hsts.includeSubDomains(true).maxAgeInSeconds(31536000))
                        .referrerPolicy(referrer -> referrer.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER))
                )
                // CSRF protection defends against a browser being tricked into
                // submitting a form using a logged-in user's session cookie.
                // We have no sessions/cookies at all - every request is
                // authenticated by its own JWT - so CSRF doesn't apply here.
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Public because they're all things you do specifically
                        // BEFORE/WITHOUT being authenticated. Logout deliberately
                        // is NOT listed here - it needs a real, valid token to
                        // revoke, so it falls under anyRequest().authenticated()
                        // below like every other endpoint.
                        .requestMatchers(
                                "/api/auth/register",
                                "/api/auth/login",
                                "/api/auth/google",
                                "/api/auth/forgot-password",
                                "/api/auth/reset-password",
                                // The whole point of a refresh token is getting a new
                                // access token once the old one has EXPIRED - requiring
                                // a valid access token to call this would defeat it.
                                // RefreshTokenService.rotate() is what actually
                                // authenticates this request, via the refresh token
                                // itself.
                                "/api/auth/refresh"
                        ).permitAll()
                        // Only the read side is public - scoped to GET
                        // specifically, so admin-only writes on
                        // /api/admin/categories (AdminCategoryController,
                        // gated by its own @PreAuthorize) don't inherit this
                        // permitAll just for sharing the "categories" word.
                        .requestMatchers(HttpMethod.GET, "/api/categories").permitAll()
                        // "/api/providers/me" and "/api/providers/{id}" have the
                        // same URL shape ("/api/providers/<one segment>"), so
                        // Spring Security can't tell them apart by pattern alone -
                        // only declaration ORDER does. This more specific "me"
                        // rule must come BEFORE the wildcard below, or a GET
                        // to /api/providers/me with no token would fall through
                        // to the wildcard's permitAll (a 403 from @PreAuthorize
                        // instead of the correct 401 for a missing token).
                        .requestMatchers(HttpMethod.GET, "/api/providers/me").authenticated()
                        // Provider search/browse (GET /api/providers and
                        // GET /api/providers/{id}) is public - see
                        // ProviderProfileService's doc comments on why only
                        // APPROVED providers ever come back from these.
                        .requestMatchers(HttpMethod.GET, "/api/providers", "/api/providers/*").permitAll()
                        // A provider's reviews are as public as their profile -
                        // anyone deciding whether to book them can read what
                        // past customers said, logged in or not.
                        .requestMatchers(HttpMethod.GET, "/api/providers/*/reviews").permitAll()
                        // Uploaded avatars are public images (shown on profiles
                        // anyone can view), served by StaticResourceConfig -
                        // requiring a JWT just to display a picture would be
                        // pointless friction with no real security benefit.
                        .requestMatchers(HttpMethod.GET, "/uploads/**").permitAll()
                        // The WebSocket handshake itself carries no
                        // Authorization header (browsers can't set custom
                        // headers on it) - real auth happens inside
                        // ChatWebSocketHandler via the token query
                        // parameter instead, immediately on connect.
                        .requestMatchers("/ws/**").permitAll()
                        .anyRequest().authenticated()
                )
                // Without these, a missing/invalid token and an insufficient
                // role would both fall back to Spring Security's default
                // (an empty-body 403 for both) - see each handler's own
                // Javadoc for why we tell them apart.
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(restAuthenticationEntryPoint)
                        .accessDeniedHandler(restAccessDeniedHandler)
                )
                // Run our JWT check before Spring's own filter (which we never
                // use, since we have no username/password login FORM).
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
