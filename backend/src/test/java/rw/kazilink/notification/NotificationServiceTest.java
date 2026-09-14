package rw.kazilink.notification;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.push.PushNotificationService;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private PushNotificationService pushNotificationService;

    @InjectMocks
    private NotificationService notificationService;

    private final UUID userId = UUID.randomUUID();

    @Test
    void listForUser_mapsEveryNotificationToAResponse() {
        Notification notification = new Notification(userId, "Request accepted", "Bob accepted your request", UUID.randomUUID());
        when(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId)).thenReturn(List.of(notification));

        List<NotificationResponse> responses = notificationService.listForUser(userId);

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).title()).isEqualTo("Request accepted");
    }

    @Test
    void markRead_marksTheCallersOwnNotification() {
        Notification notification = new Notification(userId, "Job started", "Bob started your job", null);
        UUID notificationId = UUID.randomUUID();
        notification.setId(notificationId);
        when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));

        notificationService.markRead(userId, notificationId);

        assertThat(notification.isRead()).isTrue();
    }

    @Test
    void markRead_throwsWhenTheNotificationBelongsToSomeoneElse() {
        Notification notification = new Notification(UUID.randomUUID(), "Job started", "Bob started your job", null);
        UUID notificationId = UUID.randomUUID();
        notification.setId(notificationId);
        when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));

        assertThatThrownBy(() -> notificationService.markRead(userId, notificationId))
                .isInstanceOf(NotificationNotFoundException.class);
    }

    @Test
    void markAllRead_marksEveryUnreadNotificationForThatUser() {
        Notification first = new Notification(userId, "A", "a", null);
        Notification second = new Notification(userId, "B", "b", null);
        when(notificationRepository.findByUserIdAndReadFalse(userId)).thenReturn(List.of(first, second));

        notificationService.markAllRead(userId);

        assertThat(first.isRead()).isTrue();
        assertThat(second.isRead()).isTrue();
        verify(notificationRepository).saveAll(List.of(first, second));
    }

    @Test
    void create_savesANewUnreadNotification() {
        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);

        notificationService.create(userId, "New booking request", "Alice requested Pipe fix", null);

        verify(notificationRepository, times(1)).save(captor.capture());
        Notification saved = captor.getValue();
        assertThat(saved.getUserId()).isEqualTo(userId);
        assertThat(saved.getTitle()).isEqualTo("New booking request");
        assertThat(saved.isRead()).isFalse();
    }
}
