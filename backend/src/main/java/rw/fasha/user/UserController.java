package rw.fasha.user;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

/**
 * "My account" self-service endpoints - every role (customer, provider,
 * admin) uses these, unlike ProviderProfileController which is
 * provider-only business-profile data. None of these routes are in
 * SecurityConfig's permitAll list, so every request here must already
 * carry a valid JWT - @AuthenticationPrincipal hands us that token's user
 * id directly.
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public UserResponse getMe(@AuthenticationPrincipal UUID userId) {
        return userService.getMe(userId);
    }

    @PatchMapping("/me")
    public UserResponse updateProfile(@AuthenticationPrincipal UUID userId, @Valid @RequestBody UpdateProfileRequest request) {
        return userService.updateProfile(userId, request);
    }

    @PutMapping("/me/password")
    public ResponseEntity<Void> changePassword(@AuthenticationPrincipal UUID userId, @Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(userId, request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(path = "/me/avatar")
    public UserResponse uploadAvatar(@AuthenticationPrincipal UUID userId, @RequestParam("file") MultipartFile file) {
        return userService.updateAvatar(userId, file);
    }
}
