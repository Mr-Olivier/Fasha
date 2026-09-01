package rw.kazilink.otp;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.email.BrevoEmailService;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OtpServiceTest {

    @Mock
    private OtpCodeRepository otpCodeRepository;

    @Mock
    private BrevoEmailService emailService;

    @InjectMocks
    private OtpService otpService;

    private final UUID userId = UUID.randomUUID();

    @Test
    void issue_savesACodeAndEmailsIt() {
        User user = new User("Alice Uwase", "alice@example.com", null, "hash", Role.CUSTOMER);
        user.setId(userId);
        when(otpCodeRepository.save(any(OtpCode.class))).thenAnswer(invocation -> invocation.getArgument(0));

        otpService.issue(user, OtpPurpose.EMAIL_VERIFICATION, "Verify your email", "Here's your code:");

        ArgumentCaptor<OtpCode> captor = ArgumentCaptor.forClass(OtpCode.class);
        verify(otpCodeRepository).save(captor.capture());
        OtpCode saved = captor.getValue();
        assertThat(saved.getUserId()).isEqualTo(userId);
        assertThat(saved.getPurpose()).isEqualTo(OtpPurpose.EMAIL_VERIFICATION);
        assertThat(saved.getCode()).hasSize(6);
        assertThat(saved.getCode()).containsOnlyDigits();

        verify(emailService).sendOtpEmail(eq("alice@example.com"), eq("Alice Uwase"), eq("Verify your email"), anyString(), eq(saved.getCode()));
    }

    @Test
    void verifyAndConsume_returnsTrueAndMarksUsedForAValidCode() {
        OtpCode code = new OtpCode(userId, OtpPurpose.PASSWORD_RESET, "123456", Instant.now().plusSeconds(600));
        when(otpCodeRepository.findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc(userId, OtpPurpose.PASSWORD_RESET, "123456"))
                .thenReturn(Optional.of(code));

        boolean result = otpService.verifyAndConsume(userId, OtpPurpose.PASSWORD_RESET, "123456");

        assertThat(result).isTrue();
        assertThat(code.getUsedAt()).isNotNull();
        verify(otpCodeRepository).save(code);
    }

    @Test
    void verifyAndConsume_returnsFalseForAnExpiredCode() {
        OtpCode expired = new OtpCode(userId, OtpPurpose.PASSWORD_RESET, "123456", Instant.now().minusSeconds(60));
        when(otpCodeRepository.findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc(userId, OtpPurpose.PASSWORD_RESET, "123456"))
                .thenReturn(Optional.of(expired));

        boolean result = otpService.verifyAndConsume(userId, OtpPurpose.PASSWORD_RESET, "123456");

        assertThat(result).isFalse();
        verify(otpCodeRepository, never()).save(any());
    }

    @Test
    void verifyAndConsume_returnsFalseForAnAlreadyUsedCode() {
        OtpCode used = new OtpCode(userId, OtpPurpose.PASSWORD_RESET, "123456", Instant.now().plusSeconds(600));
        used.setUsedAt(Instant.now().minusSeconds(10));
        when(otpCodeRepository.findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc(userId, OtpPurpose.PASSWORD_RESET, "123456"))
                .thenReturn(Optional.of(used));

        boolean result = otpService.verifyAndConsume(userId, OtpPurpose.PASSWORD_RESET, "123456");

        assertThat(result).isFalse();
    }

    @Test
    void verifyAndConsume_returnsFalseWhenNoCodeMatches() {
        when(otpCodeRepository.findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc(userId, OtpPurpose.PASSWORD_RESET, "000000"))
                .thenReturn(Optional.empty());

        boolean result = otpService.verifyAndConsume(userId, OtpPurpose.PASSWORD_RESET, "000000");

        assertThat(result).isFalse();
    }
}
