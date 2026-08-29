package rw.kazilink.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import rw.kazilink.security.JwtService;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;
import rw.kazilink.user.UserStatus;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the business rules in AuthService. These don't start
 * Spring or touch a real database at all - UserRepository/PasswordEncoder/
 * JwtService are Mockito "fakes" we fully control, which is what makes
 * this test run in milliseconds instead of seconds.
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

    @InjectMocks
    private AuthService authService;

    private RegisterRequest validRegisterRequest;

    @BeforeEach
    void setUp() {
        validRegisterRequest = new RegisterRequest(
                "Alice Uwase", "alice@example.com", "0788000000", "password123", Role.CUSTOMER);
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
    void register_hashesPasswordAndReturnsToken() {
        when(userRepository.existsByEmail("alice@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("hashed-password");
        when(jwtService.generateToken(any(), anyString())).thenReturn("fake-jwt-token");

        AuthResponse response = authService.register(validRegisterRequest);

        assertThat(response.token()).isEqualTo("fake-jwt-token");
        assertThat(response.email()).isEqualTo("alice@example.com");
        assertThat(response.role()).isEqualTo(Role.CUSTOMER);
        // The raw password must never reach the repository - only the hash.
        verifyUserWasSavedWithHash("hashed-password");
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
        User existingUser = new User("Alice Uwase", "alice@example.com", null, "hashed-password", Role.CUSTOMER);
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("wrong-password", "hashed-password")).thenReturn(false);

        LoginRequest request = new LoginRequest("alice@example.com", "wrong-password");

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void login_rejectsSuspendedAccount() {
        User suspendedUser = new User("Alice Uwase", "alice@example.com", null, "hashed-password", Role.CUSTOMER);
        suspendedUser.setStatus(UserStatus.SUSPENDED);
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(suspendedUser));
        when(passwordEncoder.matches("password123", "hashed-password")).thenReturn(true);

        LoginRequest request = new LoginRequest("alice@example.com", "password123");

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(SuspendedAccountException.class);
    }

    @Test
    void login_returnsTokenOnCorrectPassword() {
        User existingUser = new User("Alice Uwase", "alice@example.com", null, "hashed-password", Role.CUSTOMER);
        when(userRepository.findByEmail("alice@example.com")).thenReturn(Optional.of(existingUser));
        when(passwordEncoder.matches("password123", "hashed-password")).thenReturn(true);
        when(jwtService.generateToken(any(), anyString())).thenReturn("fake-jwt-token");

        AuthResponse response = authService.login(new LoginRequest("alice@example.com", "password123"));

        assertThat(response.token()).isEqualTo("fake-jwt-token");
    }

    private void verifyUserWasSavedWithHash(String expectedHash) {
        var captor = org.mockito.ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getPasswordHash()).isEqualTo(expectedHash);
    }
}
