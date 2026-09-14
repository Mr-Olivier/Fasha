package rw.kazilink.push;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, UUID> {

    /** Powers PushNotificationService.sendToUser() - every device to push to for one recipient. */
    List<DeviceToken> findByUserId(UUID userId);

    /** Used by register() to decide insert-vs-move-ownership - see DeviceTokenService's doc comment. */
    Optional<DeviceToken> findByToken(String token);

    /** Scoped to the caller's own user id, not deleteByToken(token) alone - a token is an opaque string, but there's no reason to let a caller unregister a device they don't even own. */
    void deleteByTokenAndUserId(String token, UUID userId);
}
