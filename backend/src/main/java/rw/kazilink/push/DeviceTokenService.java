package rw.kazilink.push;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DeviceTokenService {

    private final DeviceTokenRepository deviceTokenRepository;

    /**
     * Registers (or re-registers) a device for push notifications. A
     * token that already exists gets MOVED to the calling user rather than
     * duplicated - see V33__create_device_tokens.sql's doc comment for why
     * `token` is the real unique key: the same physical device's token
     * showing up again usually means a different person is now logged in
     * on it (a shared/borrowed phone, or simply logging out and back in as
     * someone else), and pushes for that device should follow whoever's
     * actually using it now, not silently keep going to the previous user.
     */
    @Transactional
    public void register(UUID userId, RegisterDeviceTokenRequest request) {
        DeviceToken deviceToken = deviceTokenRepository.findByToken(request.token())
                .orElseGet(() -> new DeviceToken(userId, request.token(), request.platform()));
        deviceToken.setUserId(userId);
        deviceToken.setPlatform(request.platform());
        deviceTokenRepository.save(deviceToken);
    }

    /** Called on logout (see AuthController.logout on the mobile side) - idempotent, same as unregistering a token that was never registered (or one that belongs to someone else, which this silently no-ops rather than erroring on). */
    @Transactional
    public void unregister(UUID userId, String token) {
        deviceTokenRepository.deleteByTokenAndUserId(token, userId);
    }
}
