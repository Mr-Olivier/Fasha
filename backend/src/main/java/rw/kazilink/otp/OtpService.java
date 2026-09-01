package rw.kazilink.otp;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.email.BrevoEmailService;
import rw.kazilink.user.User;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * Generates, emails, and later verifies the 6-digit codes both
 * AuthService.register() (EMAIL_VERIFICATION) and
 * AuthService.forgotPassword()/resetPassword() (PASSWORD_RESET) use - one
 * mechanism for both, since "prove you control this email address right
 * now" is the same underlying need either way.
 */
@Service
@RequiredArgsConstructor
public class OtpService {

    /** How long a code stays usable before it must be re-requested. */
    private static final long CODE_VALID_MINUTES = 10;

    private final OtpCodeRepository otpCodeRepository;
    private final BrevoEmailService emailService;
    private final SecureRandom random = new SecureRandom();

    /**
     * Deliberately doesn't throw if the email fails to send (see
     * BrevoEmailService's Javadoc) - register() and forgotPassword() must
     * both still succeed even if the mail provider is down, since the code
     * itself is safely stored either way and a resend can always be
     * requested.
     */
    @Transactional
    public void issue(User user, OtpPurpose purpose, String subject, String heading) {
        String code = generateCode();
        otpCodeRepository.save(new OtpCode(user.getId(), purpose, code, Instant.now().plus(Duration.ofMinutes(CODE_VALID_MINUTES))));
        emailService.sendOtpEmail(user.getEmail(), user.getName(), subject, heading, code);
    }

    /** Returns whether `code` was valid for this user/purpose, consuming it (marking it used) if so - a used or expired code can never verify twice. */
    @Transactional
    public boolean verifyAndConsume(UUID userId, OtpPurpose purpose, String code) {
        return otpCodeRepository.findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc(userId, purpose, code)
                .filter(OtpCode::isValid)
                .map(otp -> {
                    otp.setUsedAt(Instant.now());
                    otpCodeRepository.save(otp);
                    return true;
                })
                .orElse(false);
    }

    private String generateCode() {
        return String.format("%06d", random.nextInt(1_000_000));
    }
}
