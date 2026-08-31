package rw.kazilink.user;

import java.util.UUID;

/**
 * What the app gets back after fetching or editing "my account" - every
 * field the Profile screen needs, minus the password hash it must never see.
 */
public record UserResponse(
        UUID userId,
        String name,
        String email,
        String phone,
        Role role,
        String profileImageUrl
) {

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhone(),
                user.getRole(),
                user.getProfileImageUrl()
        );
    }
}
