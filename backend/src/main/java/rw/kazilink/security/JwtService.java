package rw.kazilink.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

/**
 * Everything to do with creating and reading JWTs lives here - nowhere else
 * in the app should import the jjwt library directly.
 *
 * A JWT looks like "header.payload.signature". We put the user's id and
 * role in the payload ("claims"), then sign the whole thing with our
 * secret key. Anyone can read a JWT's payload (it's just base64, not
 * encrypted) but nobody can FORGE or TAMPER with one without knowing the
 * secret - that's what parseClaims()'s signature check guarantees.
 *
 * {@code @RequiredArgsConstructor} (Lombok) generates a constructor that
 * takes every `final` field below - here just `properties` - so Spring can
 * inject it without us writing the constructor by hand.
 */
@Service
@RequiredArgsConstructor
public class JwtService {

    private final JwtProperties properties;

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(properties.secret().getBytes(StandardCharsets.UTF_8));
    }

    /** Issues a new token for the given user, valid for app.jwt.expiration-ms. */
    public String generateToken(UUID userId, String role) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("role", role)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(properties.expirationMs())))
                .signWith(signingKey())
                .compact();
    }

    /**
     * Verifies the signature and expiry, then returns the claims inside.
     * Throws io.jsonwebtoken.JwtException if the token is expired, was
     * tampered with, or wasn't signed with our secret.
     */
    public Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public UUID extractUserId(String token) {
        return UUID.fromString(parseClaims(token).getSubject());
    }

    public String extractRole(String token) {
        return parseClaims(token).get("role", String.class);
    }
}
