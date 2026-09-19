package rw.fasha.push;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.when;

/**
 * Only exercises the "Firebase isn't configured" fallback path -
 * FirebaseMessaging/FirebaseApp are Google-owned static-factory classes
 * that aren't practical to mock, so the actual send path is covered by
 * live testing instead (see PROJECT_STATUS.md). What IS worth a unit
 * test: this service must never throw just because no one's set
 * FIREBASE_CREDENTIALS_PATH, the same guarantee BrevoEmailServiceTest
 * would assert for its own "no API key" fallback.
 */
@ExtendWith(MockitoExtension.class)
class PushNotificationServiceTest {

    @Mock
    private DeviceTokenRepository deviceTokenRepository;

    private final UUID userId = UUID.randomUUID();

    @Test
    void sendToUser_doesNothingWhenFirebaseIsntConfigured() {
        PushNotificationService service = new PushNotificationService(new FirebaseProperties(""), deviceTokenRepository);
        when(deviceTokenRepository.findByUserId(userId))
                .thenReturn(List.of(new DeviceToken(userId, "some-fcm-token", DevicePlatform.ANDROID)));

        assertThatCode(() -> service.sendToUser(userId, "New booking request", "Alice requested Pipe fix"))
                .doesNotThrowAnyException();
    }

    @Test
    void sendToUser_doesNothingWhenTheUserHasNoRegisteredDevices() {
        PushNotificationService service = new PushNotificationService(new FirebaseProperties(""), deviceTokenRepository);
        when(deviceTokenRepository.findByUserId(userId)).thenReturn(List.of());

        assertThatCode(() -> service.sendToUser(userId, "New booking request", "Alice requested Pipe fix"))
                .doesNotThrowAnyException();
    }
}
