package rw.kazilink.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

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

    /**
     * BCrypt is a one-way hash designed to be deliberately slow, so
     * brute-forcing leaked password hashes is impractical. We NEVER store
     * a plain-text password - only what this encoder produces.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // CSRF protection defends against a browser being tricked into
                // submitting a form using a logged-in user's session cookie.
                // We have no sessions/cookies at all - every request is
                // authenticated by its own JWT - so CSRF doesn't apply here.
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**").permitAll()
                        .anyRequest().authenticated()
                )
                // Run our JWT check before Spring's own filter (which we never
                // use, since we have no username/password login FORM).
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
