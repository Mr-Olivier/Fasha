package rw.fasha.security;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Issues and rotates refresh tokens - the long-lived credential a client
 * trades in for a new short-lived access token (see JwtService/JwtProperties)
 * without the user having to log in again. See V20's migration comment for
 * the full rotation design.
 *
 * The actual token handed to the client is a random 256-bit value, NOT a
 * JWT - unlike the access token, it's opaque and meaningless without a
 * database lookup, which is exactly what makes it revocable on demand
 * (logout, admin-forced suspension) rather than merely "valid until it
 * naturally expires".
 */
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private static final Logger log = LoggerFactory.getLogger(RefreshTokenService.class);

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtProperties jwtProperties;
    private final SecureRandom random = new SecureRandom();

    /** Issues a brand new refresh token for `userId`, unrelated to any existing one - used at login/register, not rotation. */
    @Transactional
    public String issue(UUID userId) {
        return issueAndSave(userId, null);
    }

    /**
     * Trades a valid, unused refresh token for a new one, revoking the old
     * one in the same transaction (rotation). Returns both the new token's
     * owning userId and the new plaintext token.
     *
     * If `plaintextToken` has ALREADY been revoked (its row exists but
     * revoked=true), that's a strong signal it was stolen and used a
     * second time by someone other than its legitimate owner (the
     * legitimate owner's client only ever presents each refresh token
     * once, immediately replacing it) - we respond by revoking every
     * other still-live token for that user too, forcing a fresh login
     * everywhere, the same defensive move browsers and major auth
     * providers use for "refresh token reuse detection".
     */
    @Transactional
    public RotatedToken rotate(String plaintextToken) {
        String hash = hash(plaintextToken);
        RefreshToken existing = refreshTokenRepository.findByTokenHash(hash).orElseThrow(InvalidRefreshTokenException::new);

        if (existing.isRevoked()) {
            log.warn("Reused (already-revoked) refresh token presented for user {} - revoking all their sessions.", existing.getUserId());
            revokeAllForUser(existing.getUserId());
            throw new InvalidRefreshTokenException();
        }
        if (existing.getExpiresAt().isBefore(Instant.now())) {
            throw new InvalidRefreshTokenException();
        }

        UUID userId = existing.getUserId();
        String newPlaintext = issueAndSave(userId, existing.getId());

        existing.setRevoked(true);
        refreshTokenRepository.save(existing);

        return new RotatedToken(userId, newPlaintext);
    }

    /** Called at logout - a client that explicitly signs out shouldn't leave its refresh token usable afterwards. */
    @Transactional
    public void revoke(String plaintextToken) {
        refreshTokenRepository.findByTokenHash(hash(plaintextToken))
                .ifPresent(token -> {
                    token.setRevoked(true);
                    refreshTokenRepository.save(token);
                });
    }

    /** Called when an admin suspends/deletes an account - every refresh token they're holding (any device) must stop working immediately, not just their current access token. */
    @Transactional
    public void revokeAllForUser(UUID userId) {
        refreshTokenRepository.findByUserIdAndRevokedFalse(userId)
                .forEach(t -> {
                    t.setRevoked(true);
                    refreshTokenRepository.save(t);
                });
    }

    private String issueAndSave(UUID userId, UUID replacesTokenId) {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String plaintext = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        RefreshToken token = new RefreshToken(userId, hash(plaintext), Instant.now().plusMillis(jwtProperties.refreshExpirationMs()));
        refreshTokenRepository.save(token);

        if (replacesTokenId != null) {
            RefreshToken old = refreshTokenRepository.findById(replacesTokenId).orElse(null);
            if (old != null) {
                old.setReplacedByTokenId(token.getId());
                refreshTokenRepository.save(old);
            }
        }

        return plaintext;
    }

    private String hash(String plaintext) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(plaintext.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashed);
        } catch (NoSuchAlgorithmException e) {
            // SHA-256 is a mandatory JDK algorithm (JLS-guaranteed) - this can never actually happen.
            throw new IllegalStateException(e);
        }
    }

    public record RotatedToken(UUID userId, String plaintextToken) {
    }
}
