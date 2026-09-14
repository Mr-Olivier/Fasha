package rw.kazilink.common;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * A small, generic per-key rate limiter backed by Redis (not an in-memory
 * map) so the count survives an app restart and works correctly across
 * more than one backend instance - the same reasoning LoginAttemptService
 * documents for its own Redis-backed counters below.
 *
 * Fixed window, not a sliding one: simpler, and "at most N of this action
 * per window, resetting on the window boundary" is plenty precise for
 * abuse prevention - this isn't billing-grade metering. Implemented with
 * Redis's INCR (atomic even under concurrent requests) + an EXPIRE set
 * only on the first increment, which is the standard fixed-window-counter
 * pattern: the key's own TTL IS the window, so there's nothing to clean up
 * or reset by hand.
 */
@Component
@RequiredArgsConstructor
public class RateLimiter {

    private final StringRedisTemplate redisTemplate;

    /** Throws RateLimitExceededException if `key` has already been used `maxCalls` times within the current `window`. */
    public void checkAllowed(String key, int maxCalls, Duration window) {
        String redisKey = "ratelimit:" + key;
        Long count = redisTemplate.opsForValue().increment(redisKey);
        // Only the request that just created the key (count == 1) sets its
        // expiry - every later increment within the same window must NOT
        // touch the TTL, or the window would keep sliding forward forever
        // instead of resetting on a fixed boundary.
        if (count != null && count == 1L) {
            redisTemplate.expire(redisKey, window);
        }
        if (count != null && count > maxCalls) {
            throw new RateLimitExceededException();
        }
    }
}
