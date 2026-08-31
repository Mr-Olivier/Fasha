package rw.kazilink.auth;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.security.JwtService;
import rw.kazilink.security.RevokedToken;
import rw.kazilink.security.RevokedTokenRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;
import rw.kazilink.user.UserStatus;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * All the business rules for registering and logging in live here. The
 * controller stays "thin" - it only translates HTTP <-> this service, with
 * no logic of its own to test or reason about.
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    /** How long a "forgot password" link stays usable before it must be requested again. */
    private static final long RESET_TOKEN_VALID_MINUTES = 30;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RevokedTokenRepository revokedTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;

    /**
     * {@code @Transactional}: if anything after userRepository.save() threw
     * an exception, the save would be rolled back too, so we never end up
     * with a half-created user. Not strictly necessary yet (nothing else
     * touches the database here), but this is the right default the moment
     * a service method does more than one write.
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (request.role() == Role.ADMIN) {
            throw new InvalidRegistrationRoleException();
        }
        if (userRepository.existsByEmail(request.email())) {
            throw new EmailAlreadyExistsException(request.email());
        }

        User user = new User(
                request.name(),
                request.email(),
                request.phone(),
                passwordEncoder.encode(request.password()),
                request.role()
        );
        userRepository.save(user);

        String token = jwtService.generateToken(user.getId(), user.getRole().name());
        return toAuthResponse(user, token);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(InvalidCredentialsException::new);

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }
        if (user.getStatus() == UserStatus.SUSPENDED) {
            throw new SuspendedAccountException();
        }

        String token = jwtService.generateToken(user.getId(), user.getRole().name());
        return toAuthResponse(user, token);
    }

    /**
     * By the time this runs, JwtAuthenticationFilter has already verified
     * `token` is well-formed and correctly signed (SecurityConfig requires
     * authentication for this endpoint) - we don't re-validate that here,
     * just record its jti as revoked so JwtAuthenticationFilter rejects
     * this exact token on any future request, even though it hasn't
     * naturally expired yet.
     */
    public void logout(String token) {
        UUID jti = jwtService.extractJti(token);
        Instant expiresAt = jwtService.extractExpiration(token);
        revokedTokenRepository.save(new RevokedToken(jti, expiresAt));
    }

    /**
     * Always succeeds with the same generic message, whether or not `email`
     * belongs to a real account - if we responded differently for "unknown
     * email" vs "email found", anyone could use this endpoint to check
     * which addresses are registered. If the email DOES match a user, a
     * reset token is created and (since this project has no email server)
     * logged here instead of being emailed - a real production version
     * would send an email containing a link with this token and stop there;
     * it would never put the token in the HTTP response body the way
     * ForgotPasswordResponse.devResetToken does.
     */
    @Transactional
    public ForgotPasswordResponse forgotPassword(ForgotPasswordRequest request) {
        Optional<User> user = userRepository.findByEmail(request.email());
        UUID devToken = null;

        if (user.isPresent()) {
            PasswordResetToken resetToken =
                    new PasswordResetToken(user.get().getId(), Instant.now().plus(Duration.ofMinutes(RESET_TOKEN_VALID_MINUTES)));
            passwordResetTokenRepository.save(resetToken);
            devToken = resetToken.getToken();
            log.info("Password reset requested for {} - dev-mode token (would be emailed in production): {}",
                    request.email(), devToken);
        } else {
            log.info("Password reset requested for an email with no matching account: {}", request.email());
        }

        return new ForgotPasswordResponse(
                "If an account exists for that email, a reset link has been generated.", devToken);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findById(request.token())
                .filter(PasswordResetToken::isValid)
                .orElseThrow(InvalidResetTokenException::new);

        User user = userRepository.findById(resetToken.getUserId())
                .orElseThrow(InvalidResetTokenException::new);

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);

        resetToken.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(resetToken);
    }

    private AuthResponse toAuthResponse(User user, String token) {
        return new AuthResponse(token, user.getId(), user.getName(), user.getEmail(), user.getRole());
    }
}
