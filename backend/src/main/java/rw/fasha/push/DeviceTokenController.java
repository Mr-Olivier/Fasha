package rw.fasha.push;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/** Every role can receive push notifications, so nothing here is role-gated - just "authenticated" (same reasoning as NotificationController). */
@RestController
@RequestMapping("/api/device-tokens")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;

    @PostMapping
    public ResponseEntity<Void> register(@AuthenticationPrincipal UUID userId, @Valid @RequestBody RegisterDeviceTokenRequest request) {
        deviceTokenService.register(userId, request);
        return ResponseEntity.noContent().build();
    }

    /**
     * `token` in the path, not the body - DELETE with a body is
     * inconsistent across HTTP clients/proxies, and the token is already
     * URL-safe (FCM registration tokens are base64url).
     */
    @DeleteMapping("/{token}")
    public ResponseEntity<Void> unregister(@AuthenticationPrincipal UUID userId, @PathVariable String token) {
        deviceTokenService.unregister(userId, token);
        return ResponseEntity.noContent().build();
    }
}
