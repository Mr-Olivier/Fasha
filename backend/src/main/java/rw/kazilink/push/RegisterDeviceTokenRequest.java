package rw.kazilink.push;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** What the Flutter app sends to POST /api/device-tokens right after obtaining an FCM token (see mobile PushNotificationService). */
public record RegisterDeviceTokenRequest(
        @NotBlank(message = "token is required")
        String token,

        @NotNull(message = "platform is required")
        DevicePlatform platform
) {
}
