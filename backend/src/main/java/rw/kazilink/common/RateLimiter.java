package rw.kazilink.common;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A small, generic per-key rate limiter - the same in-memory,
 * fixed-window approach LoginAttemptService already uses for login
 * lockout, pulled out so other write-heavy customer actions (creating a
 * booking, leaving a review) can reuse it instead of each hand-rolling
 * their own counter. See LoginAttemptService's doc comment for why
 * in-memory (not Redis/a DB table) is the right trade-off at this scale,
 * and why that would need to change for a horizontally-scaled deployment.
 *
 * Fixed window, not a sliding one: simpler, and "at most N of this action
 * per window, resetting on the window boundary" is plenty precise for
 * abuse prevention - this isn't billing-grade metering.
 */
@Component
public class RateLimiter {

    private final ConcurrentHashMap<String, Window> windowsByKey = new ConcurrentHashMap<>();

    /** Throws RateLimitExceededException if `key` has already been used `maxCalls` times within the current `window`. */
    public void checkAllowed(String key, int maxCalls, Duration window) {
        Instant now = Instant.now();
        Window current = windowsByKey.compute(key, (k, existing) -> {
            if (existing == null || existing.startedAt.plus(window).isBefore(now)) {
                return new Window(now);
            }
            existing.count++;
            return existing;
        });
        if (current.count > maxCalls) {
            throw new RateLimitExceededException();
        }
    }

    private static final class Window {
        private final Instant startedAt;
        private volatile int count = 1;

        private Window(Instant startedAt) {
            this.startedAt = startedAt;
        }
    }
}
