package rw.kazilink.security;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/**
 * JpaRepository already gives us existsById(jti) and save(...) for free -
 * that's the entire API JwtAuthenticationFilter and AuthService.logout need.
 */
public interface RevokedTokenRepository extends JpaRepository<RevokedToken, UUID> {
}
