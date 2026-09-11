package rw.kazilink.security;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    Optional<RefreshToken> findByTokenHash(String tokenHash);

    /** Powers RefreshTokenService.revokeAllForUser - every session an admin-suspended account still holds. */
    List<RefreshToken> findByUserIdAndRevokedFalse(UUID userId);
}
