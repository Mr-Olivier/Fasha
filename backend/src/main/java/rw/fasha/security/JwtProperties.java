package rw.fasha.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Typed binding for the "app.jwt.*" keys in application.yml.
 *
 * Without this, every class that needs the JWT secret would need its own
 * @Value("${app.jwt.secret}") field - easy to typo, and there'd be no single
 * place to see every config value this app depends on. @ConfigurationProperties
 * binds a whole prefix onto one object instead (enabled via
 * @ConfigurationPropertiesScan on BackendApplication).
 */
@ConfigurationProperties(prefix = "app.jwt")
public record JwtProperties(String secret, long expirationMs, long refreshExpirationMs) {
}
