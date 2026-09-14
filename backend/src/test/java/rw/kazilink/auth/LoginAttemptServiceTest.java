package rw.kazilink.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.lenient;

/**
 * Exercises LoginAttemptService's actual lockout logic against a small
 * in-memory fake of the handful of Redis calls it makes (increment/
 * expire/getExpire/set/delete) - no real Redis server is available in
 * this test environment, and faking these calls behaviorally (rather than
 * just verifying they happened) gives genuine coverage of the lockout
 * logic itself, not just "did it call the template".
 */
@ExtendWith(MockitoExtension.class)
class LoginAttemptServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private final Map<String, AtomicLong> counters = new ConcurrentHashMap<>();
    private final Map<String, Boolean> locked = new ConcurrentHashMap<>();

    private LoginAttemptService service;

    // lenient() throughout this setUp(): not every test exercises every
    // one of these Redis calls (e.g. a test that only calls
    // assertNotLocked() never touches increment/set/delete), and
    // Mockito's default strict stubbing would otherwise fail THAT test
    // for having "unnecessary" stubs set up here for OTHER tests' use.
    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        lenient().when(valueOperations.increment(anyString()))
                .thenAnswer(inv -> counters.computeIfAbsent(inv.getArgument(0), k -> new AtomicLong()).incrementAndGet());

        // set(key, value, timeout) returns void, not Boolean - doAnswer, not when().thenAnswer(), is the Mockito shape for stubbing a void method.
        lenient().doAnswer(inv -> {
            locked.put(inv.getArgument(0), true);
            return null;
        }).when(valueOperations).set(anyString(), anyString(), any(Duration.class));

        lenient().when(redisTemplate.getExpire(anyString(), eq(TimeUnit.SECONDS)))
                .thenAnswer(inv -> locked.getOrDefault((String) inv.getArgument(0), false) ? 900L : -2L);

        lenient().when(redisTemplate.delete(any(List.class)))
                .thenAnswer(inv -> {
                    List<String> keys = inv.getArgument(0);
                    keys.forEach(k -> {
                        counters.remove(k);
                        locked.remove(k);
                    });
                    return (long) keys.size();
                });

        service = new LoginAttemptService(redisTemplate);
    }

    @Test
    void assertNotLocked_allowsAnEmailWithNoHistory() {
        assertThatCode(() -> service.assertNotLocked("nobody@example.com")).doesNotThrowAnyException();
    }

    @Test
    void assertNotLocked_allowsAFewFailuresBelowTheThreshold() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("alice@example.com");
        }

        assertThatCode(() -> service.assertNotLocked("alice@example.com")).doesNotThrowAnyException();
    }

    @Test
    void assertNotLocked_locksOutAfterFiveFailures() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("alice@example.com");
        }

        assertThatThrownBy(() -> service.assertNotLocked("alice@example.com"))
                .isInstanceOf(AccountLockedException.class);
    }

    @Test
    void recordSuccess_clearsAnyPriorFailures() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("alice@example.com");
        }
        service.recordSuccess("alice@example.com");
        // One more failure right after a success should NOT trip the
        // 5-failure threshold, since the counter reset to zero.
        service.recordFailure("alice@example.com");

        assertThatCode(() -> service.assertNotLocked("alice@example.com")).doesNotThrowAnyException();
    }

    @Test
    void lockout_isCaseInsensitiveAndTrimsWhitespaceOnTheEmail() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("  Alice@Example.com  ");
        }

        assertThatThrownBy(() -> service.assertNotLocked("alice@example.com"))
                .isInstanceOf(AccountLockedException.class);
    }

    @Test
    void lockout_isIndependentPerEmail() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("alice@example.com");
        }

        assertThatCode(() -> service.assertNotLocked("bob@example.com")).doesNotThrowAnyException();
    }
}
