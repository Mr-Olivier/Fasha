package rw.kazilink.notification;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    /** Powers GET /api/notifications - always scoped to the caller's own id. */
    List<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId);

    long countByUserIdAndReadFalse(UUID userId);

    List<Notification> findByUserIdAndReadFalse(UUID userId);
}
