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
     * allow any localhost/127.0.0.1 port rather than hardcoding one.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("http://localhost:*", "http://127.0.0.1:*"));
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
                                "/api/auth/forgot-password",
                                "/api/auth/reset-password"
                        ).permitAll()
                        // Categories are only ever read here (admin management is
                        // Feature 9) - scoped to GET specifically, so a future
                        // admin-only POST/PUT on the same path doesn't
                        // accidentally inherit this permitAll.
                        .requestMatchers(HttpMethod.GET, "/api/categories").permitAll()
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
