package rw.kazilink.common;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Exercises RateLimiter's fixed-window counting against a small in-memory
 * fake of the Redis INCR call it makes - same reasoning as
 * LoginAttemptServiceTest for why a behavioral fake rather than just
 * verifying method calls happened.
 */
@ExtendWith(MockitoExtension.class)
class RateLimiterTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private final Map<String, AtomicLong> counters = new ConcurrentHashMap<>();

    private RateLimiter rateLimiter;

    @BeforeEach
    void setUp() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.increment(anyString()))
                .thenAnswer(inv -> counters.computeIfAbsent(inv.getArgument(0), k -> new AtomicLong()).incrementAndGet());

        rateLimiter = new RateLimiter(redisTemplate);
    }

    @Test
    void checkAllowed_permitsCallsUpToTheLimit() {
        for (int i = 0; i < 3; i++) {
            assertThatCode(() -> rateLimiter.checkAllowed("booking:customer-1", 3, Duration.ofHours(1)))
                    .doesNotThrowAnyException();
        }
    }

    @Test
    void checkAllowed_rejectsOnceOverTheLimit() {
        for (int i = 0; i < 3; i++) {
            rateLimiter.checkAllowed("booking:customer-1", 3, Duration.ofHours(1));
        }

        assertThatThrownBy(() -> rateLimiter.checkAllowed("booking:customer-1", 3, Duration.ofHours(1)))
                .isInstanceOf(RateLimitExceededException.class);
    }

    @Test
    void checkAllowed_keysAreIndependent() {
        for (int i = 0; i < 3; i++) {
            rateLimiter.checkAllowed("booking:customer-1", 3, Duration.ofHours(1));
        }

        // A different key (e.g. a different customer, or a different
        // action's namespace) has its own counter entirely.
        assertThatCode(() -> rateLimiter.checkAllowed("booking:customer-2", 3, Duration.ofHours(1)))
                .doesNotThrowAnyException();
    }
}
