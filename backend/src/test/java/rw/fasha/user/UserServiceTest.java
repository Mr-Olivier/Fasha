package rw.fasha.user;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the business rules in UserService. AvatarStorageService is
 * mocked here too (not just the repository/encoder) so these tests never
 * touch the real filesystem - see AvatarStorageService's own doc comment
 * for why it's a separate, mockable class.
 */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AvatarStorageService avatarStorageService;

    @InjectMocks
    private UserService userService;

    @Test
    void getMe_throwsWhenTheUserNoLongerExists() {
        UUID userId = UUID.randomUUID();
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.getMe(userId)).isInstanceOf(UserNotFoundException.class);
    }

    @Test
    void updateProfile_changesNameAndPhone() {
        UUID userId = UUID.randomUUID();
        User user = new User("Alice Uwase", "alice@example.com", "0788000000", "hashed-password", Role.CUSTOMER);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));

        UserResponse response = userService.updateProfile(userId, new UpdateProfileRequest("Alice K.", "0788999999"));

        assertThat(response.name()).isEqualTo("Alice K.");
        assertThat(response.phone()).isEqualTo("0788999999");
    }

    @Test
    void changePassword_rejectsAnIncorrectCurrentPassword() {
        UUID userId = UUID.randomUUID();
        User user = new User("Alice Uwase", "alice@example.com", null, "hashed-password", Role.CUSTOMER);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrong-current", "hashed-password")).thenReturn(false);

        assertThatThrownBy(() -> userService.changePassword(userId, new ChangePasswordRequest("wrong-current", "newpassword123")))
                .isInstanceOf(IncorrectCurrentPasswordException.class);
    }

    @Test
    void changePassword_updatesTheHashOnCorrectCurrentPassword() {
        UUID userId = UUID.randomUUID();
        User user = new User("Alice Uwase", "alice@example.com", null, "old-hash", Role.CUSTOMER);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("old-password", "old-hash")).thenReturn(true);
        when(passwordEncoder.encode("new-password123")).thenReturn("new-hash");

        userService.changePassword(userId, new ChangePasswordRequest("old-password", "new-password123"));

        assertThat(user.getPasswordHash()).isEqualTo("new-hash");
    }

    @Test
    void updateAvatar_savesTheReturnedUrlOnTheUser() {
        UUID userId = UUID.randomUUID();
        User user = new User("Alice Uwase", "alice@example.com", null, "hashed-password", Role.CUSTOMER);
        MockMultipartFile file = new MockMultipartFile("file", "me.jpg", "image/jpeg", new byte[]{1, 2, 3});
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(avatarStorageService.store(any(), any())).thenReturn("/uploads/avatars/some-file.jpg");

        UserResponse response = userService.updateAvatar(userId, file);

        assertThat(response.profileImageUrl()).isEqualTo("/uploads/avatars/some-file.jpg");
    }
}
