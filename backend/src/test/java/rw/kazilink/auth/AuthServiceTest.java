package rw.kazilink.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import rw.kazilink.otp.InvalidOtpException;
import rw.kazilink.otp.OtpPurpose;
import rw.kazilink.otp.OtpService;
import rw.kazilink.security.JwtService;
import rw.kazilink.security.RefreshTokenService;
import rw.kazilink.security.RevokedToken;
import rw.kazilink.security.RevokedTokenRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;
import rw.kazilink.user.UserStatus;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the business rules in AuthService. These don't start
 * Spring or touch a real database at all - UserRepository/PasswordEncoder/
 * JwtService/OtpService are Mockito "fakes" we fully control, which is
 * what makes this test run in milliseconds instead of seconds.
 *
 * README.md section 20 calls out "Authentication" and "Authorisation" as
 * the backend behaviour most worth testing for this MVP - this class is
 * that coverage.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private RevokedTokenRepository revokedTokenRepository;

    @Mock
    private OtpService otpService;

    @Mock
    private LoginAttemptService loginAttemptService;

    @InjectMocks
    private AuthService authService;

    private RegisterRequest validRegisterRequest;

    @BeforeEach
    void setUp() {
        validRegisterRequest = new RegisterRequest(
                "Alice Uwase", "alice@example.com", "0788000000", "password123", Role.CUSTOMER);
    }

    private User verifiedUser(String passwordHash) {
        User user = new User("Alice Uwase", "alice@example.com", null, passwordHash, Role.CUSTOMER);
        user.setEmailVerified(true);
        return user;
    }

    @Test
    void register_rejectsAdminRole() {
        RegisterRequest asAdmin = new RegisterRequest(
                "Alice Uwase", "alice@example.com", "0788000000", "password123", Role.ADMIN);

        assertThatThrownBy(() -> authService.register(asAdmin))
                .isInstanceOf(InvalidRegistrationRoleException.class);
    }

    @Test
    void register_rejectsDuplicateEmail() {
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(validRegisterRequest))
                .isInstanceOf(EmailAlreadyExistsException.class);
    }

    @Test
    void register_hashesPasswordAndReturnsAnUnverifiedTokenWhileIssuingAnOtp() {
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("hashed-password");
        when(jwtService.generateToken(any(), anyString())).thenReturn("fake-jwt-token");

        AuthResponse response = authService.register(validRegisterRequest);

        assertThat(response.token()).isEqualTo("fake-jwt-token");
        assertThat(response.email()).isEqualTo("alice@example.com");
        assertThat(response.role()).isEqualTo(Role.CUSTOMER);
        assertThat(response.emailVerified()).isFalse();
        // The raw password must never reach the repository - only the hash.
        verifyUserWasSavedWithHash("hashed-password");
        verify(otpService).issue(any(User.class), eq(OtpPurpose.EMAIL_VERIFICATION), anyString(), anyString());
    }

    @Test
    void login_rejectsUnknownEmail() {
        when(userRepository.findByEmail("nobody@example.com")).thenReturn(Optional.empty());

        LoginRequest request = new LoginRequest("nobody@example.com", "password123");

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_rejectsWrongPassword() {
        User existingUser = verifiedUser("hashed-password");
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("wrong-password", "hashed-password")).thenReturn(false);

        LoginRequest request = new LoginRequest("alice@example.com", "wrong-password");

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_rejectsSuspendedAccount() {
        User suspendedUser = verifiedUser("hashed-password");
        suspendedUser.setStatus(UserStatus.SUSPENDED);
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(suspendedUser));
        when(passwordEncoder.matches("password123", "hashed-password")).thenReturn(true);

        LoginRequest request = new LoginRequest("alice@example.com", "password123");

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(SuspendedAccountException.class);
    }

    @Test
    void login_rejectsAnUnverifiedEmail() {
        User unverifiedUser = new User("Alice Uwase", "alice@example.com", null, "hashed-password", Role.CUSTOMER);
        unverifiedUser.setEmailVerified(false);
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(unverifiedUser));
        when(passwordEncoder.matches("password123", "hashed-password")).thenReturn(true);

        LoginRequest request = new LoginRequest("alice@example.com", "password123");

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(EmailNotVerifiedException.class);
    }

    @Test
    void login_returnsTokenOnCorrectPassword() {
        User existingUser = verifiedUser("hashed-password");
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("password123", "hashed-password")).thenReturn(true);
        when(jwtService.generateToken(any(), anyString())).thenReturn("fake-jwt-token");
        when(refreshTokenService.issue(any())).thenReturn("fake-refresh-token");

        AuthResponse response = authService.login(new LoginRequest("alice@example.com", "password123"));

        assertThat(response.token()).isEqualTo("fake-jwt-token");
        assertThat(response.refreshToken()).isEqualTo("fake-refresh-token");
        assertThat(response.emailVerified()).isTrue();
        verify(loginAttemptService).recordSuccess("alice@example.com");
    }

    @Test
    void login_checksForAnExistingLockoutBeforeTouchingCredentials() {
        org.mockito.Mockito.doThrow(new AccountLockedException(5)).when(loginAttemptService).assertNotLocked("alice@example.com");

        assertThatThrownBy(() -> authService.login(new LoginRequest("alice@example.com", "password123")))
                .isInstanceOf(AccountLockedException.class);
        verify(userRepository, never()).findByEmail(any());
    }

    @Test
    void login_recordsAFailedAttemptOnWrongPassword() {
        User existingUser = verifiedUser("hashed-password");
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("wrong-password", "hashed-password")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(new LoginRequest("alice@example.com", "wrong-password")))
                .isInstanceOf(InvalidCredentialsException.class);

        verify(loginAttemptService).recordFailure("alice@example.com");
        verify(loginAttemptService, never()).recordSuccess(any());
    }

    @Test
    void refresh_rotatesTheRefreshTokenAndReturnsTheUsersCurrentDetails() {
        User existingUser = verifiedUser("hashed-password");
        existingUser.setId(UUID.randomUUID());
        when(refreshTokenService.rotate("old-refresh-token"))
                .thenReturn(new RefreshTokenService.RotatedToken(existingUser.getId(), "new-refresh-token"));
        when(userRepository.findById(existingUser.getId())).thenReturn(Optional.of(existingUser));
        when(jwtService.generateToken(existingUser.getId(), "CUSTOMER")).thenReturn("new-access-token");

        AuthResponse response = authService.refresh("old-refresh-token");

        assertThat(response.token()).isEqualTo("new-access-token");
        assertThat(response.refreshToken()).isEqualTo("new-refresh-token");
        assertThat(response.email()).isEqualTo("alice@example.com");
    }

    @Test
    void refresh_rejectsASuspendedAccountEvenWithAValidRefreshToken() {
        User suspendedUser = verifiedUser("hashed-password");
        suspendedUser.setId(UUID.randomUUID());
        suspendedUser.setStatus(UserStatus.SUSPENDED);
        when(refreshTokenService.rotate("old-refresh-token"))
                .thenReturn(new RefreshTokenService.RotatedToken(suspendedUser.getId(), "new-refresh-token"));
        when(userRepository.findById(suspendedUser.getId())).thenReturn(Optional.of(suspendedUser));

        assertThatThrownBy(() -> authService.refresh("old-refresh-token"))
                .isInstanceOf(SuspendedAccountException.class);
    }

    @Test
    void logout_revokesTheTokensJti() {
        UUID jti = UUID.randomUUID();
        Instant expiresAt = Instant.now().plusSeconds(3600);
        when(jwtService.extractJti("some-jwt")).thenReturn(jti);
        when(jwtService.extractExpiration("some-jwt")).thenReturn(expiresAt);

        authService.logout("some-jwt", null);

        var captor = org.mockito.ArgumentCaptor.forClass(RevokedToken.class);
        verify(revokedTokenRepository).save(captor.capture());
        assertThat(captor.getValue().getJti()).isEqualTo(jti);
        assertThat(captor.getValue().getExpiresAt()).isEqualTo(expiresAt);
    }

    @Test
    void verifyEmail_marksTheAccountVerifiedOnAValidCode() {
        UUID userId = UUID.randomUUID();
        User user = new User("Alice Uwase", "alice@example.com", null, "hash", Role.CUSTOMER);
        user.setId(userId);
        user.setEmailVerified(false);
        when(otpService.verifyAndConsume(userId, OtpPurpose.EMAIL_VERIFICATION, "123456")).thenReturn(true);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        authService.verifyEmail(userId, "123456");

        assertThat(user.isEmailVerified()).isTrue();
    }

    @Test
    void verifyEmail_throwsOnAnInvalidCode() {
        UUID userId = UUID.randomUUID();
        when(otpService.verifyAndConsume(userId, OtpPurpose.EMAIL_VERIFICATION, "000000")).thenReturn(false);

        assertThatThrownBy(() -> authService.verifyEmail(userId, "000000"))
                .isInstanceOf(InvalidOtpException.class);
    }

    @Test
    void forgotPassword_doesNotIssueAnOtpForAnUnknownEmail() {
        when(userRepository.findByEmail("nobody@example.com")).thenReturn(Optional.empty());

        ForgotPasswordResponse response = authService.forgotPassword(new ForgotPasswordRequest("nobody@example.com"));

        // The message is identical either way - see forgotPassword's Javadoc
        // for why we never reveal whether the email exists via the response.
        assertThat(response.message()).isNotBlank();
        verify(otpService, never()).issue(any(), any(), anyString(), anyString());
    }

    @Test
    void forgotPassword_issuesAPasswordResetOtpForAKnownEmail() {
        User existingUser = verifiedUser("hashed-password");
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));

        authService.forgotPassword(new ForgotPasswordRequest("alice@example.com"));

        verify(otpService).issue(eq(existingUser), eq(OtpPurpose.PASSWORD_RESET), anyString(), anyString());
    }

    @Test
    void resetPassword_rejectsAnUnknownEmail() {
        when(userRepository.findByEmail("nobody@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.resetPassword(new ResetPasswordRequest("nobody@example.com", "123456", "newpassword123")))
                .isInstanceOf(InvalidOtpException.class);
    }

    @Test
    void resetPassword_rejectsAnInvalidCode() {
        User existingUser = verifiedUser("old-hash");
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(otpService.verifyAndConsume(existingUser.getId(), OtpPurpose.PASSWORD_RESET, "000000")).thenReturn(false);

        assertThatThrownBy(() -> authService.resetPassword(new ResetPasswordRequest("alice@example.com", "000000", "newpassword123")))
                .isInstanceOf(InvalidOtpException.class);
    }

    @Test
    void resetPassword_updatesThePasswordOnAValidCode() {
        User existingUser = verifiedUser("old-hash");
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(otpService.verifyAndConsume(existingUser.getId(), OtpPurpose.PASSWORD_RESET, "123456")).thenReturn(true);
        when(passwordEncoder.encode("newpassword123")).thenReturn("new-hash");

        authService.resetPassword(new ResetPasswordRequest("alice@example.com", "123456", "newpassword123"));

        assertThat(existingUser.getPasswordHash()).isEqualTo("new-hash");
    }

    private void verifyUserWasSavedWithHash(String expectedHash) {
        var captor = org.mockito.ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getPasswordHash()).isEqualTo(expectedHash);
    }
}
