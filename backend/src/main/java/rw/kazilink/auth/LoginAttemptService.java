package rw.kazilink.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.TimeUnit;

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
 * Backed by Redis (two keys per email - a failure counter and a lockout
 * flag, both with a TTL), not an in-memory map: this used to be a plain
 * ConcurrentHashMap, which meant every lockout silently reset on every app
 * restart/redeploy, and wouldn't work correctly at all across more than
 * one backend instance (each instance would have its own independent
 * counter, so an attacker could just get 4 failures against each of N
 * instances behind a load balancer without ever tripping the limit).
 * Redis fixes both: one shared counter, and it survives a restart.
 *
 * One deliberate behavior change from the old in-memory version: the
 * failure counter itself now expires after LOCKOUT_DURATION of no new
 * failures (via the same TTL the lockout key gets), rather than persisting
 * forever until either a success or an actual lockout. That's a rolling
 * window, which is the more standard/correct brute-force-protection shape
 * anyway, and avoids Redis quietly accumulating one key per email address
 * anyone has ever mistyped a password for.
 */
@Service
@RequiredArgsConstructor
public class LoginAttemptService {

    private static final int MAX_ATTEMPTS = 5;
    private static final Duration LOCKOUT_DURATION = Duration.ofMinutes(15);

    private final StringRedisTemplate redisTemplate;

    /** Call before checking credentials - throws if this email is currently locked out. */
    public void assertNotLocked(String email) {
        Long secondsRemaining = redisTemplate.getExpire(lockKey(email), TimeUnit.SECONDS);
        if (secondsRemaining == null || secondsRemaining <= 0) {
            return;
        }
        long minutesRemaining = Math.max(1, (secondsRemaining + 59) / 60);
        throw new AccountLockedException(minutesRemaining);
    }

    /** Call whenever a login attempt for `email` failed (unknown email or wrong password) - counts toward the lockout threshold. */
    public void recordFailure(String email) {
        String countKey = countKey(email);
        Long count = redisTemplate.opsForValue().increment(countKey);
        // Only the FIRST failure in a fresh window starts its TTL - see
        // RateLimiter's identical comment for why later increments must
        // not touch it.
        if (count != null && count == 1L) {
            redisTemplate.expire(countKey, LOCKOUT_DURATION);
        }
        if (count != null && count >= MAX_ATTEMPTS) {
            redisTemplate.opsForValue().set(lockKey(email), "1", LOCKOUT_DURATION);
        }
    }

    /** Call on a successful login - a legitimate sign-in resets the counter, so a few genuine typos don't linger toward a future lockout. */
    public void recordSuccess(String email) {
        redisTemplate.delete(List.of(countKey(email), lockKey(email)));
    }

    private String countKey(String email) {
        return "login:failcount:" + normalize(email);
    }

    private String lockKey(String email) {
        return "login:lockout:" + normalize(email);
    }

    private String normalize(String email) {
        return email.trim().toLowerCase();
    }
}
