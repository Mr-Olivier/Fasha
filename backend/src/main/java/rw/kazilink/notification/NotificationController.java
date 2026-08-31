package rw.kazilink.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/** Every role (customer, provider, admin) can have notifications, so nothing here is role-gated - just "authenticated". */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public List<NotificationResponse> list(@AuthenticationPrincipal UUID userId) {
        return notificationService.listForUser(userId);
    }

    @GetMapping("/unread-count")
    public long unreadCount(@AuthenticationPrincipal UUID userId) {
        return notificationService.countUnread(userId);
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<Void> markRead(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        notificationService.markRead(userId, id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/read-all")
    public ResponseEntity<Void> markAllRead(@AuthenticationPrincipal UUID userId) {
        notificationService.markAllRead(userId);
        return ResponseEntity.noContent().build();
    }
}
