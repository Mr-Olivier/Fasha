package rw.fasha.push;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeviceTokenServiceTest {

    @Mock
    private DeviceTokenRepository deviceTokenRepository;

    @InjectMocks
    private DeviceTokenService deviceTokenService;

    @Test
    void register_savesANewTokenForAFirstTimeDevice() {
        UUID userId = UUID.randomUUID();
        when(deviceTokenRepository.findByToken("fcm-token-1")).thenReturn(Optional.empty());

        deviceTokenService.register(userId, new RegisterDeviceTokenRequest("fcm-token-1", DevicePlatform.ANDROID));

        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(deviceTokenRepository).save(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo(userId);
        assertThat(captor.getValue().getToken()).isEqualTo("fcm-token-1");
        assertThat(captor.getValue().getPlatform()).isEqualTo(DevicePlatform.ANDROID);
    }

    @Test
    void register_movesAnExistingTokenToTheNewCallerInsteadOfDuplicatingIt() {
        UUID previousOwner = UUID.randomUUID();
        UUID newOwner = UUID.randomUUID();
        DeviceToken existing = new DeviceToken(previousOwner, "shared-device-token", DevicePlatform.ANDROID);
        when(deviceTokenRepository.findByToken("shared-device-token")).thenReturn(Optional.of(existing));

        deviceTokenService.register(newOwner, new RegisterDeviceTokenRequest("shared-device-token", DevicePlatform.ANDROID));

        // Same object identity as `existing`, not a freshly constructed one -
        // this is a move (UPDATE), not a second row (INSERT).
        ArgumentCaptor<DeviceToken> captor = ArgumentCaptor.forClass(DeviceToken.class);
        verify(deviceTokenRepository).save(captor.capture());
        assertThat(captor.getValue()).isSameAs(existing);
        assertThat(captor.getValue().getUserId()).isEqualTo(newOwner);
    }

    @Test
    void unregister_isScopedToTheCallersOwnTokenNotJustAnyToken() {
        UUID userId = UUID.randomUUID();

        deviceTokenService.unregister(userId, "some-token");

        verify(deviceTokenRepository).deleteByTokenAndUserId("some-token", userId);
    }
}
