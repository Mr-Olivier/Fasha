package rw.kazilink.auth;

import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Brute-force protection for POST /api/auth/login: after
 * [MAX_ATTEMPTS] failed attempts for the same email within
 * [LOCKOUT_DURATION], further attempts are rejected outright (even with
 * the correct password) until the lockout expires - a standard defense
 * against an attacker guessing passwords.
 *
 * Deliberately keyed by EMAIL, not IP address: an attacker can trivially
 * rotate IPs, but the one thing that stays constant across their attempts
 * is the account they're trying to break into. Keying by IP would also
 * incorrectly punish many legitimate users behind the same NAT/office
 * network for one person's typos.
 *
 * In-memory (ConcurrentHashMap), not a database table: login attempts are
 * high-frequency, short-lived-relevance data - exactly what you don't want
 * adding write load to Postgres for. The trade-off is that this resets on
 * app restart and doesn't share state across multiple backend instances;
 * a horizontally-scaled deployment would swap this for a Redis-backed
 * counter with the same interface, which is why every method here is
 * expressed as a small, swappable unit rather than inlined into
 * AuthService directly.
 */
@Service
public class LoginAttemptService {

    private static final int MAX_ATTEMPTS = 5;
    private static final Duration LOCKOUT_DURATION = Duration.ofMinutes(15);

    private final ConcurrentHashMap<String, Attempts> attemptsByEmail = new ConcurrentHashMap<>();

    /** Call before checking credentials - throws if this email is currently locked out. */
    public void assertNotLocked(String email) {
        Attempts attempts = attemptsByEmail.get(normalize(email));
        if (attempts == null || attempts.lockedUntil == null) {
            return;
        }
        Instant now = Instant.now();
        if (attempts.lockedUntil.isAfter(now)) {
            long minutesRemaining = Math.max(1, Duration.between(now, attempts.lockedUntil).toMinutes());
            throw new AccountLockedException(minutesRemaining);
        }
        // Lockout window has passed - clear it out so this email starts fresh.
        attemptsByEmail.remove(normalize(email));
    }

    /** Call whenever a login attempt for `email` failed (unknown email or wrong password) - counts toward the lockout threshold. */
    public void recordFailure(String email) {
        attemptsByEmail.compute(normalize(email), (key, existing) -> {
            Attempts attempts = existing == null ? new Attempts() : existing;
            attempts.failedCount++;
            if (attempts.failedCount >= MAX_ATTEMPTS) {
                attempts.lockedUntil = Instant.now().plus(LOCKOUT_DURATION);
            }
            return attempts;
        });
    }

    /** Call on a successful login - a legitimate sign-in resets the counter, so a few genuine typos don't linger toward a future lockout. */
    public void recordSuccess(String email) {
        attemptsByEmail.remove(normalize(email));
    }

    private String normalize(String email) {
        return email.trim().toLowerCase();
    }

    private static final class Attempts {
        private int failedCount = 0;
        private volatile Instant lockedUntil;
    }
}
