package rw.kazilink.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.otp.InvalidOtpException;
import rw.kazilink.otp.OtpPurpose;
import rw.kazilink.otp.OtpService;
import rw.kazilink.security.JwtService;
import rw.kazilink.security.RefreshTokenService;
import rw.kazilink.security.RevokedToken;
import rw.kazilink.security.RevokedTokenRepository;
import rw.kazilink.user.AuthProvider;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;
import rw.kazilink.user.UserStatus;

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

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final RevokedTokenRepository revokedTokenRepository;
    private final OtpService otpService;
    private final GoogleTokenService googleTokenService;
    private final LoginAttemptService loginAttemptService;

    /**
     * emailVerified starts false for every self-registered account - see
     * User.emailVerified's Javadoc - and this immediately issues an
     * EMAIL_VERIFICATION code by the same OtpService that
     * forgotPassword()/resetPassword() use. The response still carries a
     * real, usable JWT (see AuthResponse.emailVerified) rather than
     * stranding the new user with no session at all - the mobile app is
     * what actually blocks navigation past the "verify your email" screen
     * (app_router.dart's redirect) until that flips true. login() is the
     * one place this IS enforced server-side, for anyone who closes the
     * app before verifying and comes back later.
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
        user.setEmailVerified(false);
        userRepository.save(user);

        otpService.issue(user, OtpPurpose.EMAIL_VERIFICATION,
                "Verify your KaziLink email", "Welcome to KaziLink! Use this code to verify your email:");

        return toAuthResponse(user);
    }

    /**
     * Fails closed BEFORE touching the database at all if this email is
     * currently locked out (see LoginAttemptService) - a locked-out
     * attacker doesn't even get the timing signal of a real credential
     * check running. Every wrong-password/unknown-email attempt counts
     * toward that lockout; a successful one clears it.
     */
    public AuthResponse login(LoginRequest request) {
        loginAttemptService.assertNotLocked(request.email());

        Optional<User> maybeUser = userRepository.findByEmail(request.email());
        if (maybeUser.isEmpty() || !passwordEncoder.matches(request.password(), maybeUser.get().getPasswordHash())) {
            loginAttemptService.recordFailure(request.email());
            throw new InvalidCredentialsException();
        }
        User user = maybeUser.get();
        loginAttemptService.recordSuccess(request.email());

        if (user.getStatus() == UserStatus.SUSPENDED) {
            throw new SuspendedAccountException();
        }
        if (!user.isEmailVerified()) {
            throw new EmailNotVerifiedException();
        }

        return toAuthResponse(user);
    }

    /**
     * Signs in with a Google-issued ID token, creating a new account the
     * first time this Google user is seen. Deliberately shares the same
     * response shape (and JWT-issuing tail end) as login()/register() -
     * from the Flutter app's point of view this is just another way to end
     * up with a valid session.
     *
     * An existing LOCAL account with a matching email gets linked (its
     * google_sub is filled in) rather than creating a duplicate user -
     * someone who registered with a password can start using "Continue
     * with Google" on the same account without losing anything, and their
     * password keeps working too.
     */
    @Transactional
    public AuthResponse googleAuth(GoogleAuthRequest request) {
        GoogleIdToken.Payload payload = googleTokenService.verify(request.idToken());
        if (!Boolean.TRUE.equals(payload.getEmailVerified())) {
            throw new GoogleTokenVerificationException();
        }

        String sub = payload.getSubject();
        String email = payload.getEmail();

        User user = userRepository.findByGoogleSub(sub)
                .or(() -> userRepository.findByEmail(email))
                .orElse(null);

        if (user == null) {
            if (request.role() == Role.ADMIN) {
                throw new InvalidRegistrationRoleException();
            }
            String name = (String) payload.get("name");

            user = new User();
            user.setName((name == null || name.isBlank()) ? email : name);
            user.setEmail(email);
            user.setRole(request.role() == null ? Role.CUSTOMER : request.role());
            user.setStatus(UserStatus.ACTIVE);
            user.setAuthProvider(AuthProvider.GOOGLE);
            user.setGoogleSub(sub);
            // Google already verified this address, so there's no OTP step
            // to send the user through, unlike register()'s local accounts.
            user.setEmailVerified(true);
        } else if (user.getGoogleSub() == null) {
            user.setGoogleSub(sub);
            user.setEmailVerified(true);
        }
        userRepository.save(user);

        if (user.getStatus() == UserStatus.SUSPENDED) {
            throw new SuspendedAccountException();
        }

        return toAuthResponse(user);
    }

    /**
     * Trades a still-valid refresh token for a brand new access+refresh
     * pair, rotating the refresh token in the process (see
     * RefreshTokenService.rotate's Javadoc for what "rotating" means and
     * why). Public (see SecurityConfig) since the access token that would
     * normally authenticate a request is exactly what's expired here.
     */
    public AuthResponse refresh(String refreshToken) {
        RefreshTokenService.RotatedToken rotated = refreshTokenService.rotate(refreshToken);
        User user = userRepository.findById(rotated.userId()).orElseThrow(UserNotFoundException::new);
        if (user.getStatus() == UserStatus.SUSPENDED) {
            throw new SuspendedAccountException();
        }

        String accessToken = jwtService.generateToken(user.getId(), user.getRole().name());
        return new AuthResponse(
                accessToken, rotated.plaintextToken(), user.getId(), user.getName(), user.getEmail(),
                user.getPhone(), user.getProfileImageUrl(), user.getRole(), user.isEmailVerified()
        );
    }

    /** Called from the "verify your email" screen when the original register() code expired or never arrived - issues a fresh one for the same account. */
    public void resendVerification(UUID userId) {
        User user = userRepository.findById(userId).orElseThrow(UserNotFoundException::new);
        otpService.issue(user, OtpPurpose.EMAIL_VERIFICATION,
                "Your new KaziLink verification code", "Here's your new verification code:");
    }

    @Transactional
    public void verifyEmail(UUID userId, String code) {
        if (!otpService.verifyAndConsume(userId, OtpPurpose.EMAIL_VERIFICATION, code)) {
            throw new InvalidOtpException();
        }
        User user = userRepository.findById(userId).orElseThrow(UserNotFoundException::new);
        user.setEmailVerified(true);
        userRepository.save(user);
    }

    /**
     * By the time this runs, JwtAuthenticationFilter has already verified
     * `token` is well-formed and correctly signed (SecurityConfig requires
     * authentication for this endpoint) - we don't re-validate that here,
     * just record its jti as revoked so JwtAuthenticationFilter rejects
     * this exact token on any future request, even though it hasn't
     * naturally expired yet.
     */
    public void logout(String token, String refreshToken) {
        UUID jti = jwtService.extractJti(token);
        Instant expiresAt = jwtService.extractExpiration(token);
        revokedTokenRepository.save(new RevokedToken(jti, expiresAt));
        // Optional for backward compatibility with a client that hasn't
        // updated yet - the access token above is still revoked either way.
        if (refreshToken != null && !refreshToken.isBlank()) {
            refreshTokenService.revoke(refreshToken);
        }
    }

    /**
     * Always succeeds with the same generic message, whether or not `email`
     * belongs to a real account - if we responded differently for "unknown
     * email" vs "email found", anyone could use this endpoint to check
     * which addresses are registered. If the email DOES match a user, an
     * OTP code is issued the same way register() issues one, and emailed
     * via Brevo (BrevoEmailService) - never returned in this response.
     */
    @Transactional
    public ForgotPasswordResponse forgotPassword(ForgotPasswordRequest request) {
        Optional<User> user = userRepository.findByEmail(request.email());

        if (user.isPresent()) {
            otpService.issue(user.get(), OtpPurpose.PASSWORD_RESET,
                    "Your KaziLink password reset code", "Use this code to reset your password:");
        } else {
            log.info("Password reset requested for an email with no matching account: {}", request.email());
        }

        return new ForgotPasswordResponse("If an account exists for that email, a verification code has been sent.");
    }

    /** InvalidOtpException doubles as "no such account" here too, deliberately - same "don't reveal what you can't touch" reasoning as forgotPassword's generic message. */
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByEmail(request.email()).orElseThrow(InvalidOtpException::new);

        if (!otpService.verifyAndConsume(user.getId(), OtpPurpose.PASSWORD_RESET, request.code())) {
            throw new InvalidOtpException();
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    private AuthResponse toAuthResponse(User user) {
        String accessToken = jwtService.generateToken(user.getId(), user.getRole().name());
        String refreshToken = refreshTokenService.issue(user.getId());
        return new AuthResponse(
                accessToken, refreshToken, user.getId(), user.getName(), user.getEmail(),
                user.getPhone(), user.getProfileImageUrl(), user.getRole(), user.isEmailVerified()
        );
    }
}
