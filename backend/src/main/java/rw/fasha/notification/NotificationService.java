package rw.fasha.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.fasha.push.PushNotificationService;

import java.util.List;
import java.util.UUID;

/**
 * Two kinds of caller use this class: NotificationController (reading/
 * marking-read, on behalf of the logged-in user) and other features'
 * services - BookingService and AdminProviderService - creating a
 * notification for SOMEONE ELSE as a side effect of their own action (e.g.
 * BookingService.accept() notifies the customer, not the provider who just
 * called it). The `create` methods take no @AuthenticationPrincipal-derived
 * caller id for that reason - the recipient is deliberately a different
 * user than whoever triggered the event.
 */
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final PushNotificationService pushNotificationService;

    public List<NotificationResponse> listForUser(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(NotificationResponse::from)
                .toList();
    }

    public long countUnread(UUID userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    @Transactional
    public void markRead(UUID userId, UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .filter(n -> n.getUserId().equals(userId))
                .orElseThrow(NotificationNotFoundException::new);
        notification.setRead(true);
        notificationRepository.save(notification);
    }

    @Transactional
    public void markAllRead(UUID userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndReadFalse(userId);
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
    }

    /**
     * Used by other features to create a notification as a side effect of
     * their own action. Also fires a real push notification (FCM) to
     * every device this user has registered - see PushNotificationService
     * for why that's safe to call unconditionally even when no push
     * provider is configured, or the user has no registered devices.
     */
    @Transactional
    public void create(UUID userId, String title, String body, UUID bookingId) {
        notificationRepository.save(new Notification(userId, title, body, bookingId));
        pushNotificationService.sendToUser(userId, title, body);
    }
}
