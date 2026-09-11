package rw.kazilink.auth;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LoginAttemptServiceTest {

    private final LoginAttemptService service = new LoginAttemptService();

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
