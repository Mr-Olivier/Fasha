package rw.kazilink.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.security.JwtService;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;
import rw.kazilink.user.UserStatus;

/**
 * All the business rules for registering and logging in live here. The
 * controller stays "thin" - it only translates HTTP <-> this service, with
 * no logic of its own to test or reason about.
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

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

    private AuthResponse toAuthResponse(User user, String token) {
        return new AuthResponse(token, user.getId(), user.getName(), user.getEmail(), user.getRole());
    }
}
