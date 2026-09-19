package rw.fasha.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    // Built by hand (not @InjectMocks) since the second constructor
    // argument, JwtProperties, is a plain record with no behaviour of its
    // own - a real instance is simpler and clearer here than mocking it.
    // Must be built in @BeforeEach, not a field initializer: the latter
    // would run before MockitoExtension injects @Mock fields, leaving
    // refreshTokenRepository null at construction time.
    private RefreshTokenService refreshTokenService;

    @BeforeEach
    void setUp() {
        refreshTokenService = new RefreshTokenService(refreshTokenRepository, new JwtProperties("test-secret", 900_000, 2_592_000_000L));
    }

    private static String sha256Hex(String plaintext) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(plaintext.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    @Test
    void issue_savesANewTokenForTheUser() {
        UUID userId = UUID.randomUUID();

        String plaintext = refreshTokenService.issue(userId);

        assertThat(plaintext).isNotBlank();
        ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenRepository).save(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo(userId);
        assertThat(captor.getValue().getTokenHash()).isEqualTo(sha256Hex(plaintext));
        assertThat(captor.getValue().isRevoked()).isFalse();
    }

    @Test
    void rotate_returnsANewTokenAndRevokesTheOldOne() {
        UUID userId = UUID.randomUUID();
        String oldPlaintext = "old-token-value";
        RefreshToken existing = new RefreshToken(userId, sha256Hex(oldPlaintext), Instant.now().plusSeconds(60));
        when(refreshTokenRepository.findByTokenHash(sha256Hex(oldPlaintext))).thenReturn(Optional.of(existing));

        RefreshTokenService.RotatedToken rotated = refreshTokenService.rotate(oldPlaintext);

        assertThat(rotated.userId()).isEqualTo(userId);
        assertThat(rotated.plaintextToken()).isNotBlank().isNotEqualTo(oldPlaintext);
        assertThat(existing.isRevoked()).isTrue();
    }

    @Test
    void rotate_throwsForAnUnknownToken() {
        when(refreshTokenRepository.findByTokenHash(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> refreshTokenService.rotate("unknown-token"))
                .isInstanceOf(InvalidRefreshTokenException.class);
    }

    @Test
    void rotate_throwsForAnExpiredToken() {
        UUID userId = UUID.randomUUID();
        String plaintext = "expired-token";
        RefreshToken expired = new RefreshToken(userId, sha256Hex(plaintext), Instant.now().minusSeconds(60));
        when(refreshTokenRepository.findByTokenHash(sha256Hex(plaintext))).thenReturn(Optional.of(expired));

        assertThatThrownBy(() -> refreshTokenService.rotate(plaintext))
                .isInstanceOf(InvalidRefreshTokenException.class);
    }

    /**
     * The core reuse-detection guarantee: presenting a refresh token that
     * was ALREADY rotated away (revoked=true) is a signal of theft, not a
     * normal retry - the legitimate client never presents the same token
     * twice. See RefreshTokenService.rotate's Javadoc.
     */
    @Test
    void rotate_revokesEveryOtherSessionWhenAnAlreadyRevokedTokenIsReused() {
        UUID userId = UUID.randomUUID();
        String plaintext = "stolen-token";
        RefreshToken alreadyRevoked = new RefreshToken(userId, sha256Hex(plaintext), Instant.now().plusSeconds(60));
        alreadyRevoked.setRevoked(true);
        when(refreshTokenRepository.findByTokenHash(sha256Hex(plaintext))).thenReturn(Optional.of(alreadyRevoked));

        RefreshToken otherLiveSession = new RefreshToken(userId, "other-hash", Instant.now().plusSeconds(60));
        when(refreshTokenRepository.findByUserIdAndRevokedFalse(userId)).thenReturn(List.of(otherLiveSession));

        assertThatThrownBy(() -> refreshTokenService.rotate(plaintext))
                .isInstanceOf(InvalidRefreshTokenException.class);

        assertThat(otherLiveSession.isRevoked()).isTrue();
        verify(refreshTokenRepository, times(1)).save(otherLiveSession);
    }

    @Test
    void revoke_marksTheMatchingTokenRevoked() {
        UUID userId = UUID.randomUUID();
        String plaintext = "some-token";
        RefreshToken token = new RefreshToken(userId, sha256Hex(plaintext), Instant.now().plusSeconds(60));
        when(refreshTokenRepository.findByTokenHash(sha256Hex(plaintext))).thenReturn(Optional.of(token));

        refreshTokenService.revoke(plaintext);

        assertThat(token.isRevoked()).isTrue();
    }

    @Test
    void revoke_doesNothingForAnUnknownToken() {
        when(refreshTokenRepository.findByTokenHash(any())).thenReturn(Optional.empty());

        refreshTokenService.revoke("unknown-token");

        verify(refreshTokenRepository, never()).save(any());
    }

    @Test
    void revokeAllForUser_revokesEveryLiveTokenForThatUserOnly() {
        UUID userId = UUID.randomUUID();
        RefreshToken first = new RefreshToken(userId, "hash-1", Instant.now().plusSeconds(60));
        RefreshToken second = new RefreshToken(userId, "hash-2", Instant.now().plusSeconds(60));
        when(refreshTokenRepository.findByUserIdAndRevokedFalse(userId)).thenReturn(List.of(first, second));

        refreshTokenService.revokeAllForUser(userId);

        assertThat(first.isRevoked()).isTrue();
        assertThat(second.isRevoked()).isTrue();
    }
}
