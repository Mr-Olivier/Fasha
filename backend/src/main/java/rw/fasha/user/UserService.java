package rw.fasha.user;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

/**
 * Business rules for a logged-in user managing their OWN account - viewing
 * it, editing name/phone, changing their password, and uploading an
 * avatar. Nothing here lets a user act on anyone else's account: every
 * method takes the userId straight from the caller's own JWT (see
 * UserController's @AuthenticationPrincipal), never from a request body.
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AvatarStorageService avatarStorageService;

    public UserResponse getMe(UUID userId) {
        return UserResponse.from(findUserOrThrow(userId));
    }

    @Transactional
    public UserResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = findUserOrThrow(userId);
        user.setName(request.name());
        user.setPhone(request.phone());
        userRepository.save(user);
        return UserResponse.from(user);
    }

    @Transactional
    public void changePassword(UUID userId, ChangePasswordRequest request) {
        User user = findUserOrThrow(userId);
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new IncorrectCurrentPasswordException();
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }

    @Transactional
    public UserResponse updateAvatar(UUID userId, MultipartFile file) {
        User user = findUserOrThrow(userId);
        user.setProfileImageUrl(avatarStorageService.store(userId, file));
        userRepository.save(user);
        return UserResponse.from(user);
    }

    /**
     * userId comes straight from a verified JWT (see this class's own doc
     * comment) - a missing row here would mean the user was deleted after
     * their token was issued, not a normal "not found" a client caused, but
     * we still need SOME exception rather than letting Optional.get() throw
     * an unchecked NoSuchElementException.
     */
    private User findUserOrThrow(UUID userId) {
        return userRepository.findById(userId).orElseThrow(UserNotFoundException::new);
    }
}
